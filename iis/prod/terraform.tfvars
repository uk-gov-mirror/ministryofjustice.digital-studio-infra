
# TODO note which are for app module

app = "iis"
env = "prod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
always_on                   = true
app_service_plan_size       = "S1"
certificate_name            = "iis-prod-iis-prod-CERThpaDOTserviceDOThmppsDOTdsdDOTio"
certificate_name            = "iis-preprod-iis-preprod-CERThpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
create_cname                = true
create_sql_firewall         = true
custom_hostname             = "hpa.service.hmpps.dsd.io"
default_documents           = [
  "Default.htm",
  "Default.html",
  "Default.asp",
  "index.htm",
  "index.html",
  "iisstart.htm",
  "default.aspx",
  "index.php",
  "hostingstart.html"
]
firewall_rules              = [
  {
    label = "NOMS Studio office"
    start = var.ips["office"]
    end   = var.ips["office"]
  },
  {
    label = "MOJ Digital"
    start = var.ips["mojvpn"]
    end   = var.ips["mojvpn"]
  }
]
has_storage                 = true
https_only                  = true
key_vault_secrets           = [
  "signon-client-id",
  "signon-client-secret",
  "administrators"
]
repo_url                    = "https://iis-prod.scm.azurewebsites.net"
sampling_percentage         = "50"
sc_branch                   = "master"
scm_use_main_ip_restriction = true
signon_hostname             = "https://signon.service.justice.gov.uk"
setup_queries               = [
  "IF SCHEMA_ID('HPA') IS NULL EXEC sp_executesql \"CREATE SCHEMA HPA\"",
  "GRANT SELECT ON SCHEMA::HPA TO iisuser",
  "GRANT SELECT ON SCHEMA::IIS TO iisuser",
  "GRANT SELECT, INSERT, DELETE ON SCHEMA::NON_IIS TO iisuser",
  "ALTER ROLE db_datareader ADD MEMBER sgandalwar",
  "ALTER ROLE db_datawriter ADD MEMBER sgandalwar",
  "ALTER ROLE db_ddladmin ADD MEMBER sgandalwar",
  "GRANT SHOWPLAN to sgandalwar",
]
sql_collation               = "Latin1_General_CS_AS"
sql_edition                 = "Standard"
sql_scale                   = "S3"
sql_space_gb                = 250
sql_users                   = [
  "iisuser",
  "mwhitfield",
  "sgandalwar"
]
tags                        = {
  "application"      = "HPA"
  "environment_name" = "prod"
  "service"          = "Misc"
}
use_32_bit_worker_process = false