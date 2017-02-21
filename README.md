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

```
ARM_CLIENT_ID=
ARM_CLIENT_SECRET=
```

```
HEROKU_API_KEY=
HEROKU_EMAIL=
```
