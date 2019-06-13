# Digital Hub Terraform

Terraform code to provision hub infra.

### Bouncebox SSH bootstrapping

Each folder contains a public key named `sshkey.pub`. The private key can be found in dso-passwords-devtest/prod keyvaults. (hub-terraform-bootstrap-ssh) - These public keys were originally ignored by git, but we've included them so terraform can be run nightly from jenkins.

TODO: Get terraform to generate ssh keys itself.


