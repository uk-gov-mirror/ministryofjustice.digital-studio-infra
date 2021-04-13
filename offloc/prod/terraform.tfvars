app = "offloc"
env = "prod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name      = "offloc-prod-offloc-prod-CERTwwwDOTofflocDOTserviceDOTjusticeDOTgovDOTuk"
https_only            = true
sampling_percentage   = "0"
custom_hostname       = "www.offloc.service.justice.gov.uk"
has_storage           = true
app_service_plan_size = "S2"

tags = {
  application      = "NonCore"                                                   # Mandatory
  business_unit    = "HMPPS"                                                     # Mandatory
  is_production    = "true"                                                      # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "prod"
  service          = "NonCore"
  source_code      = "https://github.com/ministryofjustice/digital-studio-infra/tree/master/offloc/prod"
}
