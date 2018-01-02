const url = require('url');
const request = require('request-promise');
const azure = require('azure');
const {ServiceClient} = require('ms-rest');
const exec = require('child_process').execSync;

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

  return Object.assign({}, argv);
}

main()
  .then(() => console.log("All done"))
  .catch((err) => {
    console.error("Unexpected error", err);
    process.exit(1);
  });

async function main() {
  const args = parseArgs();
  const creds = await login(args.subscriptionId);
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

function login(subscriptionId) {
  console.log("Logging into azure...");
  return loadLocalCredentials(subscriptionId)
}

function loadLocalCredentials(subscriptionId) {
  try {
    const tokenData = exec(`az account get-access-token -s '${subscriptionId}'`);
    const data = JSON.parse(tokenData);
    const authorization = `${data.tokenType} ${data.accessToken}`;

    return {
      signRequest(webResource, callback) {
        webResource.headers.authorization = authorization;
        return callback(null);
      }
    };
  } catch (ex) {
    throw new Error(`
      Couldn't get valid azure token for ${subscriptionId}.
      Use \`az login\` to populate local credential file first.
      Error: ${ex.message}
    `);
  }
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
