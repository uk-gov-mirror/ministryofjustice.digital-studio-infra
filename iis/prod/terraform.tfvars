app = "iis"
env = "prod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name            = "iis-prod-iis-prod-CERThpaDOTserviceDOThmppsDOTdsdDOTio"
https_only                  = true
sc_branch                   = "master"
repo_url                    = "https://iis-prod.scm.azurewebsites.net"
signon_hostname             = "https://signon.service.justice.gov.uk"
sampling_percentage         = "50"
custom_hostname             = "hpa.service.hmpps.dsd.io"
has_storage                 = true
scm_use_main_ip_restriction = true

tags = {
  application      = "HPA"                                                    # Mandatory
  business_unit    = "HMPPS"                                                  # Mandatory
  is_production    = "true"                                                   # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "prod"
  service          = "Misc"
  source_code      = "https://github.com/ministryofjustice/digital-studio-infra/tree/master/iis/prod"
}
