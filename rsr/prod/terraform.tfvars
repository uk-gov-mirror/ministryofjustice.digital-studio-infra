tags = { "application" = "RSR"
  "environment_name" = "prod"
  "service"          = "Misc"
}
app              = "rsr"
env              = "prod"
certificate_name = "rsr-prod-rsr-prod-CERTrsrDOTserviceDOThmppsDOTdsdDOTio"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
https_only          = true
sampling_percentage = "50"
custom_hostname     = "rsr.service.hmpps.dsd.io"
sc_branch           = "master"
repo_url            = "https://rsr-prod.scm.azurewebsites.net"
