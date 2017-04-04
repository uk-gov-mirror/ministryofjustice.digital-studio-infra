# Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a seperate terraform environment.

## Setup

### Required Software

 * [terraform 0.9.2+](http://terraform.io/)
 * [Node.JS 6+](https://nodejs.org/)
 * [Yarn](https://yarnpkg.com/en/)

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

Install dependencies from npm using yarn
```
yarn install
```

When you want to work on a particular project environment, you'll need to initialise the terraform backend storage first.

```
terraform init
```
