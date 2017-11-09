# TODO: move this file centrally

resource "aws_s3_bucket" "state-storage" {
    bucket = "moj-studio-webops-terraform"
    acl = "private"
    versioning {
        enabled = true
    }
}
