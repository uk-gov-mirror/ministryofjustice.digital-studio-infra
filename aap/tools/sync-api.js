const url = require('url');
const request = require('request-promise');
const azure = require('azure');
const {ServiceClient} = require('ms-rest');
const KeyVault = require('azure-keyvault');
const pify = require('pify');
const pem = pify(require('pem'), {include: ['readPkcs12', 'createPkcs12']});

function parseArgs() {
  const argv = require('yargs')
    .options('tenantId', {
      demandOption: true,
    })
    .options('subscriptionId', {
      demandOption: true,
    })
    .option('resourceGroupName', {
      demandOption: true,
    })
    .option('serviceName', {
      describe: 'API Management Service name',
      demandOption: true,
    })
    .option('swaggerDefinition', {
      describe: 'URL to get swagger from',
      demandOption: true,
    })
    .option('path', {
      describe: 'API path',
      demandOption: true,
    })
    .option('apiId', {
      demandOption: true,
    })
    .option('username', {
      demandOption: true,
    })
    .option('password', {
      demandOption: true
    })
    .option('keyvault', {
      describe: 'Vault where the hostname certificate is stored',
      demandOption: true
    })
    .option('hostname', {
      demandOption: true
    })
    .argv;

  const environment = {
    clientId: getenv('ARM_CLIENT_ID'),
    clientSecret: getenv('ARM_CLIENT_SECRET'),
  };

  return Object.assign({}, argv, environment);
}

main()
  .then(() => console.log("All done"))
  .catch((err) => {
    console.error("Unexpected error", err);
    process.exit(1);
  });

async function main() {
  const args = parseArgs();
  const creds = await login(args.clientId, args.clientSecret, args.tenantId);
  const client = createAPIManagementClient(creds,
    args.subscriptionId, args.resourceGroupName, args.serviceName
  );
  const keyvault = createVaultClient(
    args.clientId, args.clientSecret, args.keyvault
  );

  const swaggerDefinition = await downloadSwagger(
    args.username, args.password, args.swaggerDefinition
  );

  await deleteAPI(client, 'echo-api');
  await importAPI(client, args.apiId, args.path, swaggerDefinition);
  await updateAPIParameters(client, args.apiId, {
    subscriptionKeyParameterNames: {
      header: 'API-Key',
      query: 'api-key'
    }
  });

  await storeProperty(client, 'password', args.password, {secret: true});

  const policy = buildPolicy(args.username, "{{password}}");
  await applyPolicy(client, args.apiId, policy);
  await addAPItoProduct(client, 'unlimited', args.apiId);

  const certificate = await downloadCertificate(keyvault, args.hostname);
  const uploadedCert = await uploadCertificate(client, "Proxy", certificate);

  await setHostname(client, "Proxy", args.hostname, uploadedCert);
}

function getenv(name) {
  if (name in process.env) {
    return process.env[name];
  }
  throw new Error(`Missing ${name} environment variable`);
}

function login(clientId, clientSecret, tenantId) {
  console.log("Logging into azure...");
  return azure.loginWithServicePrincipalSecret(
    clientId, clientSecret, tenantId
  );
}

const RG_PATH = '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}';
const API_PATH = RG_PATH + '/providers/Microsoft.ApiManagement/service/{serviceName}';

function createAPIManagementClient(creds, subscriptionId, resourceGroupName, serviceName) {
  console.log("Creating API management client...");
  const client = new ServiceClient(creds);
  return (options) => {
    options.pathTemplate = API_PATH + options.pathTemplate;
    options.pathParameters = Object.assign(
      {subscriptionId, resourceGroupName, serviceName},
      options.pathParameters
    );
    options.queryParameters = Object.assign(
      {'api-version': '2016-10-10'},
      options.queryParameters
    );
    return new Promise((resolve, reject) => {
      client.sendRequest(options, (err, body, req, res) => {
        if (err) return reject(err);
        if (res.statusCode >= 400) {
          const e = new Error(`HTTP Error ${res.statusCode}`);
          e.req = req;
          e.res = res;
          e.body = body;
          return reject(e);
        }
        return resolve(body);
      });
    });
  };
}

function createVaultClient(clientId, clientSecret, vaultUri) {
  const AuthenticationContext = require('adal-node').AuthenticationContext;
  function authenticator(challenge, callback) {
    var context = new AuthenticationContext(challenge.authorization);
    return context.acquireTokenWithClientCredentials(
      challenge.resource, clientId, clientSecret,
      function(err, response) {
        if (err) return callback(err);
        callback(null, response.tokenType + ' ' + response.accessToken);
      }
    );
  }
  const credentials = new KeyVault.KeyVaultCredentials(authenticator);
  const keyvaultClient = new KeyVault.KeyVaultClient(credentials);

  function buildSecretId(name) {
    return url.resolve(vaultUri, `secrets/${name}`);
  }
  return {
    getSecret: (name) => keyvaultClient.getSecret(buildSecretId(name))
  };
}

function downloadSwagger(username, password, uri) {
  console.log(`Downloading swagger definition from ${uri}...`);
  return request({
    uri,
    auth: {username, password},
    json: true
  });
}

function getAPI(client, apiId) {
  console.log(`Getting API ${apiId} from azure...`);
  return client({
    method: 'GET',
    pathTemplate: '/apis/{apiId}',
    pathParameters: {apiId}
  });
}

function deleteAPI(client, apiId) {
  console.log(`Deleting API ${apiId} from azure...`);
  return client({
    method: 'DELETE',
    pathTemplate: '/apis/{apiId}',
    pathParameters: {apiId},
    headers: {
      'If-Match': '*'
    },
  });
}

function importAPI(client, apiId, path, definition) {
  console.log(`Importing API ${apiId} to azure...`);
  return client({
    method: 'PUT',
    pathTemplate: '/apis/{apiId}',
    pathParameters: {apiId},
    queryParameters: {
      import: 'true',
      protocols: 'https',
      path: path,
    },
    headers: {
      'If-Match': '*',
      'Content-Type': 'application/vnd.swagger.doc+json',
    },
    body: definition
  });
}

function updateAPIParameters(client, apiId, parameters) {
  console.log(`Updating API ${apiId} properties`);
  return client({
    method: 'PATCH',
    pathTemplate: '/apis/{apiId}',
    pathParameters: {apiId},
    body: parameters,
    headers: {
      'If-Match': '*'
    },
  });
}

function storeProperty(client, name, value, {secret}) {
  console.log(`Storing property ${name}`);
  return client({
    method: 'PUT',
    pathTemplate: '/properties/{propId}',
    pathParameters: {propId: name},
    body: {
      name,
      value,
      secret: Boolean(secret)
    },
    headers: {
      'If-Match': '*'
    },
  });
}

function applyPolicy(client, apiId, policy) {
  console.log(`Applying API ${apiId} policy`);
  return client({
    method: 'PUT',
    pathTemplate: '/apis/{apiId}/policy',
    pathParameters: {apiId},
    body: policy,
    disableJsonStringifyOnBody: true,
    headers: {
      'If-Match': '*',
      'Content-Type': 'application/vnd.ms-azure-apim.policy+xml'
    },
  });
}

function buildPolicy(username, password) {
  return `
<policies>
  <inbound>
    <authentication-basic username="${username}" password="${password}" />
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
</policies>
`;
}

function addAPItoProduct(client, productId, apiId) {
  console.log(`Adding API ${apiId} to Product ${productId}`);
  return client({
    method: 'PUT',
    pathTemplate: '/products/{productId}/apis/{apiId}',
    pathParameters: {productId, apiId},
  });
}

function downloadCertificate(keyvaultClient, hostname) {
  const secretName = hostname.replace(/\./g, "DOT");
  return keyvaultClient.getSecret(secretName)
    .then((secret) => secret.value);
}

async function uploadCertificate(client, type, certificate) {
  console.log(`Uploading ${type} certificate`);

  const p12password = "tempuploadpassword";
  const certInfo = await pem.readPkcs12(Buffer.from(certificate, "base64"));
  const {pkcs12} = await pem.createPkcs12(
    certInfo.key, certInfo.cert, p12password, {certFiles: certInfo.ca}
  );

  return client({
    method: 'POST',
    pathTemplate: '/updatecertificate',
    body: {
      type,
      certificate: pkcs12.toString('base64'),
      certificate_password: p12password
    },
  });
}

function setHostname(client, type, hostname, certificate) {
  console.log(`Setting ${type} hostname to ${hostname}`);

  return client({
    method: 'POST',
    pathTemplate: '/updatehostname',
    body: {
      update: [
        {type, hostname, certificate}
      ]
    }
  });
}
