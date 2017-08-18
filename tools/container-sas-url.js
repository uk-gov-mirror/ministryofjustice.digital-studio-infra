/**
 * Terraform external data source for generating a storage SAS url
 *
 * Requires environment variables for azure auth:
 *   ARM_CLIENT_ID
 *   ARM_CLIENT_SECRET
 *
 * Expects the following structure as JSON via stdin:
 * {
 *   "subscription_id": "<subscription id>",
 *   "tenant_id": "<tenant id>",
 *   "resource_group": "<resource group name>",
 *   "storage_account": "<storage account name>",
 *   "container": "<container name>",
 *   "permissions": "<permissions string, see azure docs>",
 *   "start_date": "<start date in ISO8601 format>",
 *   "end_date": "<start date in ISO8601 format>"
 * }
 *
 * And produces the following structure as JSON via stdout:
 * {
 *   "url": "<SAS url>",
 *   "token": "<SAS token only>"
 * }
 */

const fs = require('fs');

const azure = require('azure');

main();

function main() {
  const input = loadInput();

  const clientId = process.env.ARM_CLIENT_ID;
  const clientSecret = process.env.ARM_CLIENT_SECRET;

  const resourceGroup = input.resource_group;
  const accountName = input.storage_account;
  const container = input.container;
  const permissions = input.permissions;
  const startDate = new Date(input.start_date);
  const endDate = new Date(input.end_date);

  let client;

  createStorageClient()
    .then((_client) => {
      client = _client;
      return client.listServiceSAS(
        resourceGroup,
        accountName,
        {
          canonicalizedResource: `/blob/${accountName}/${container}`,
          resource: "c",
          permissions: permissions,
          sharedAccessStartTime: startDate,
          sharedAccessExpiryTime: endDate
        }
      );
    })
    .then((response) => promisedProperties({
      sasToken: response.serviceSasToken,
      properties: client.getProperties(resourceGroup, accountName)
    }))
    .then(({sasToken, properties}) => {
      const url = properties.primaryEndpoints.blob + container + "?" + sasToken;
      console.log("%j", {url, token: sasToken});
    })
    .catch((err) => {
      console.error(err.stack);
      process.exit(1);
    });

    function createStorageClient() {
      return azure.loginWithServicePrincipalSecret(
        clientId, clientSecret, input.tenant_id
      )
        .then((creds) =>
          azure
            .createStorageManagementClient(creds, input.subscription_id)
            .storageAccounts
        );
    }
}

function loadInput() {
  const data = JSON.parse(fs.readFileSync(0, 'utf8'));
  return data;
}

function promisedProperties(object) {
  const keys = Object.keys(object);
  const values = keys.map((key) => object[key]);

  return Promise.all(values)
    .then((resolvedValues) => {
      const resolvedObject = {};
      resolvedValues.forEach((value, index) => {
        resolvedObject[keys[index]] = value;
      });
      return resolvedObject;
    });
}
