# sql user passwords should be generated from a list like below.
# keeping them listed separately to not break anything
# resource "random_id" "sql-users-passwords" {
#   for_each    = toset(var.sql_users)
#   byte_length = 16
# }

resource "random_id" "sql-iisuser-password" {
  byte_length = 16
}
