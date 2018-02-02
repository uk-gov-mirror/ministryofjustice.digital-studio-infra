### Some helpful things about running a docker container inside an azure app services....

---
App deployment webhook, so when an image in pushed to docker hub it will auto pull and deploy the new image in azure:

```bash
az webapp deployment container show-cd-url -n webops-jenkins-dev -g webops-jenkins-dev --query CI_CD_URL
```
---
Show which container is currently set to run
```bash
az webapp config container show --resource-group webops-jenkins-dev --name webops-jenkins-dev
```
---
Set the container
```bash
az webapp config container set --resource-group webops-jenkins-dev --name mw-test-app --docker-custom-image-name [repo/image:tag]
```
---
Tail the stdout from your running container, this requires *Docker container logging* switched on in the azure portal, or via the ARM template see `"httpLoggingEnabled": true`
```bash
az webapp log tail --name webops-jenkins-dev -g webops-jenkins-dev
```
