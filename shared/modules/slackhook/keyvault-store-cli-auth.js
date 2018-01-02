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

  const keyVaultClient = createVaultClient(args.vaultUri);

  return keyVaultClient.setSecret(args.secretName, args.secretValue);
}

function createVaultClient(vaultUri) {
  const credentials = new KeyVault.KeyVaultCredentials(authenticator);
  const client = new KeyVault.KeyVaultClient(credentials);

  return {
    setSecret(name, value) {
      return client.setSecret(vaultUri, name, value);
    }
  }
  function authenticator(challenge, callback) {
    getAzureAuthorizationFromCli(challenge.resource, function(err, auth) {
      if (err) return callback(err);
      return callback(null, auth.tokenType + ' ' + auth.accessToken);
    });
  }
}

function getAzureAuthorizationFromCli(resource, callback) {
  const exec = require('child_process').exec;
  exec(
    'az account get-access-token --resource "' + resource  + '"',
    function(err, result) {
      if (err) return callback(err);
      try {
        return callback(null, JSON.parse(result));
      } catch (ex) {
        return callback(ex);
      }
    }
  );
}
