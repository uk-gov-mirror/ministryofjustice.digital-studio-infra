# Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a seperate terraform environment.

## Setup

### Required Software

 * terraform (0.8.7 at time of writing)
 * Node.JS 6+

### Required Config

In order to authenticate with the Azure RM APIs you'll need an azure AD app which appropriate permissions. This is a bit annoying to set up. See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/index.html#creating-credentials) for full details.

Once you have this data, set them as environment variables before running any terraform commands.

```
ARM_CLIENT_ID=xxxxx
ARM_CLIENT_SECRET=xxxxx
```

Some directories might interact with the heroku api, you'll need to go get an API key from the admin UI to make that work.

```
HEROKU_EMAIL=xxxx
HEROKU_API_KEY=xxxxx
```

### Required Setup

Execute the command below in the each directory to initialise remote storage.

The next version of terraform (0.9+) has a new feature coming which will make this much easier.

```
terraform remote config \
  -backend=azure \
  -backend-config="arm_subscription_id=c27cfedb-f5e9-45e6-9642-0fad1a5c94e7" \
  -backend-config="arm_tenant_id=747381f4-e81f-4a43-bf68-ced6a1e14edf" \
  -backend-config="resource_group_name=webops" \
  -backend-config="storage_account_name=nomsstudiowebops" \
  -backend-config="container_name=terraform" \
  -backend-config="key=$project.terraform.tfstate"
```
