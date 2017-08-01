const KeyVault = require('azure-keyvault');
const AuthenticationContext = require('adal-node').AuthenticationContext;

function parseArgs() {
  const argv = require('yargs')
    .options('tenantId', {
      demandOption: true,
    })
    .options('subscriptionId', {
      demandOption: true,
    })
    .option('vaultUri', {
      describe: 'uri of the key vault to store into',
      demandOption: true,
    })
    .option('secretName', {
      describe: 'name of the secret',
      demandOption: true,
    })
    .option('secretValue', {
      describe: 'value of the secret',
      demandOption: true,
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

  const keyVaultClient = createVaultClient(
    args.vaultUri, args.clientId, args.clientSecret
  );

  return keyVaultClient.setSecret(args.secretName, args.secretValue);
}

function getenv(name) {
  if (name in process.env) {
    return process.env[name];
  }
  throw new Error(`Missing ${name} environment variable`);
}

function createVaultClient(vaultUri, clientId, clientSecret) {
  const credentials = new KeyVault.KeyVaultCredentials(authenticator);
  const client = new KeyVault.KeyVaultClient(credentials);

  return {
    setSecret(name, value) {
      return client.setSecret(vaultUri, name, value);
    }
  }

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
}
