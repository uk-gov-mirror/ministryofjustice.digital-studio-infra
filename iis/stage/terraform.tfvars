app = "iis"
env = "stage"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name         = "iis-stage-iis-stage-CERThpa-stageDOThmppsDOTdsdDOTio"
https_only               = true
ip_restriction_addresses = ["0.0.0.0/0", "192.0.2.2/32", "192.0.2.3/32", "192.0.2.4/32", "192.0.2.5/32", "192.0.2.6/32", "192.0.2.7/32", "192.0.2.8/32", "192.0.2.9/32", "192.0.2.10/32", "192.0.2.11/32", "192.0.2.12/32", "192.0.2.13/32", "192.0.2.14/32", "192.0.2.15/32"]
signon_hostname          = "https://www.signon.dsd.io"
sampling_percentage      = "100"
custom_hostname          = "hpa-stage.hmpps.dsd.io"
has_storage              = true
sc_branch                = "azure"
repo_url                 = "https://github.com/ministryofjustice/iis"

tags = {
  application      = "HPA"                                                       # Mandatory
  business_unit    = "HMPPS"                                                     # Mandatory
  is_production    = "false"                                                     # Mandatory
  owner            = "DSO:digital-studio-operations-team@digital.justice.gov.uk" # Mandatory
  environment_name = "devtest"
  service          = "Misc"
  source_code      = "https://github.com/ministryofjustice/digital-studio-infra/tree/master/iis/stage"
}
