# Managing AWS users

## Required Software

 * [Terraform 0.11.1+](http://terraform.io/)
 * [Python 3.6] (https://www.python.org/)
 * [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
 * [AWS CLI 1.14+] (https://aws.amazon.com/cli/)
 * [jq command line JSON processor](https://stedolan.github.io/jq/)

## Managing users

The list of users is stored as a comma separated list in an Azure key vault. Terraform/AWS always requires a complete list of users for processing. In order to manage the users we need to:

1. Retrieve existing users for each type (admins/developers etc) from the Azure key vault.
2. Add or delete users as required.
3. Save the list back to the key vault.

To do this we use the ```manage-users.py``` script.

e.g. to add two users to the developers group:

```python3 manage-users.py -e prod -u JackSmith,BobJones -a add -g developers```

Parameters:

-e, --environment The environment the user is created for. Determines the Azure key vault used.
-u, --users A comma separated list of users to add or delete.
-a, --user-action Action to take i.e. add or delete.
-g, --group The group the user will belong to e.g. developers     

## Generating an access token to use AWS CLI with MFA enabled.

A script has been created to generate the AWS security token required for the CLI when MFA is enabled. The script parameters are the AWS account number and username. The script should be sourced when run to correctly export the necessary environment variables. The security token will last for 12 hours.

1. Ensure your AWS CLI has been set up with ```aws configure```

2. Source the ```get-access-token.sh``` script to obtain an access token.

e.g. ```. ./get-access-token.sh 589133037702 JackSmith```

## Set up GPG for encryption/decryption for first time passwords

In order to set first time login passwords for AWS users we need to be able to encrypt the generated passwords using GPG.

1. Install GPG.

  e.g. For Mac
```brew install gpg```

2. ```gpg --gen-key``` Follow the prompts. The passphrase set here will be used when decrypting the generated password.

3. ```gpg --list-keys``` Get the key ID.

4. ```gpg --export public-key-id | base64 > my-public-key.asc``` Export the public key, using the ID form step 2, and save it for use with Terraform.

5. Add ```export GPG_TTY=$(tty)``` to you bash profile.

## Running Terraform to update AWS.

1. Change to the environment directory e.g. aws-users/prod

2. Run terraform plan, then apply with the parameter ```-var 'gpg_key=<path-to-public-key>'```
