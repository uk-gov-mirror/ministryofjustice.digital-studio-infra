# sql user passwords should be generated from a list like below.
# keeping them listed separately to not break anything
# resource "random_id" "sql-users-passwords" {
#   for_each    = toset(var.sql_users)
#   byte_length = 16
# }

resource "random_id" "sql-iisuser-password" {
  byte_length = 16
}
resource "random_id" "sql-mwhitfield-password" {
  byte_length = 16
}
resource "random_id" "sql-sgandalwar-password" {
  byte_length = 16
}

locals {
  # use this commented out bit if we get users from list var
  #   db_user_passwords = [
  #     for user in var.sql_users :
  #     random_id.sql-users-passwords[user].b64_url
  #   ]
  #   db_users = zipmap(
  #     var.sql_users,
  #     local.db_user_passwords
  #   )
  db_pass = random_id.sql-iisuser-password.b64_url
  db_users = {
    iisuser    = random_id.sql-iisuser-password.b64_url
    mwhitfield = random_id.sql-mwhitfield-password.b64_url
    sgandalwar = random_id.sql-sgandalwar-password.b64_url
  }
}