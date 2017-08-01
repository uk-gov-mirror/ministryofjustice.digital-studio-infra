const url = require('url');
const request = require('request-promise');
const azure = require('azure');
const {ServiceClient} = require('ms-rest');

function parseArgs() {
  const argv = require('yargs')
    .options('tenantId', {
      demandOption: true,
    })
    .options('subscriptionId', {
      demandOption: true,
    })
    .option('appName', {
      describe: 'App Service name',
      demandOption: true,
    })
    .option('urls', {
      describe: 'json array of the webhook urls, optionally base64 encoded',
      demandOption: true,
      coerce: (arg) => {
        const json = arg[0] == '[' ? arg : Buffer.from(arg, 'base64');
        return JSON.parse(json);
      }
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
  const client = createKuduClient(creds,
    args.subscriptionId, args.appName
  );

  const hooks = await getHooks(client);

  const toDelete = oldHooks(hooks, args.urls);
  const toAdd = newHooks(hooks, args.urls);

  await Promise.all([
    Promise.all(toDelete.map((h) => deleteHook(client, h))),
    Promise.all(toAdd.map((h) => addHook(client, h))),
  ]);
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

function createKuduClient(creds, subscriptionId, appName) {
  console.log("Creating kudu management client...");
  const client = new ServiceClient(creds);
  return (options) => {
    options.baseUrl = 'https://' + appName + '.scm.azurewebsites.net';
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

function getHooks(client) {
  console.log(`Getting hooks from kudu...`);
  return client({
    method: 'GET',
    pathTemplate: '/api/hooks',
  });
}

function oldHooks(hooks, urls) {
  return hooks
    .filter((hook) => urls.indexOf(hook.url) === -1)
    .map((hook) => hook.id);
}

function newHooks(hooks, urls) {
  const currentHooks = hooks.map((hook) => hook.url);
  return urls
    .filter((hook) => currentHooks.indexOf(hook) === -1);
}

function addHook(client, url) {
  console.log(`Adding hook to ${url} via kudu...`);
  return client({
    method: 'POST',
    pathTemplate: '/api/hooks',
    body: {
      url,
      event: "PostDeployment",
      insecure_ssl: false,
    },
  });
}

function deleteHook(client, id) {
  console.log(`Deleting hook ${id} from kudu...`);
  return client({
    method: 'DELETE',
    pathTemplate: '/api/hooks/{id}',
    pathParameters: {id},
  });
}
