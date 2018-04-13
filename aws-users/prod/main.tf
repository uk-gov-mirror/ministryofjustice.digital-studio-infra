variable "gpg_key" {
  type    = "string"
  default = ""
}

resource "aws_iam_group" "webops" {
  name = "WebOps"
}

resource "aws_iam_group" "developers" {
  name = "Developers"
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query {
    vault            = "${var.vault-name}"
    users-webops     = "users-webops"
    users-developers = "users-developers"
  }
}

locals {
  aws_users_webops     = "${compact(split(",",data.external.vault.result.users-webops))}"
  aws_users_developers = "${compact(split(",",data.external.vault.result.users-developers))}"
}

resource "aws_iam_user" "user" {
  count = "${length(local.aws_users_webops)}"
  name  = "${element(local.aws_users_webops, count.index)}"
}

resource "aws_iam_user" "user-developer" {
  count = "${length(local.aws_users_developers)}"
  name  = "${element(local.aws_users_developers, count.index)}"
}

resource "aws_iam_group_membership" "webops_group_membership" {
  name  = "webops-group-membership"
  users = ["${aws_iam_user.user.*.name}"]
  group = "${aws_iam_group.webops.name}"
}

resource "aws_iam_group_membership" "developers_group_membership" {
  name  = "developers-group-membership"
  users = ["${aws_iam_user.user-developer.*.name}"]
  group = "${aws_iam_group.developers.name}"
}

locals {
  all_users = "${concat(local.aws_users_webops,local.aws_users_developers)}"
}

resource "aws_iam_user_login_profile" "user" {
  count           = "${length(local.all_users)}"
  user            = "${element(local.all_users, count.index)}"
  pgp_key         = "${file(var.gpg_key)}"
  password_length = 14
}

data "template_file" "enable_mfa_policy" {
  template = "${file("../policies/enable-mfa-policy.json")}"

  vars {
    aws_account_id = "${var.aws_account_id}"
  }
}

resource "aws_iam_policy" "enable-mfa" {
  name        = "enable-mfa"
  description = "Enable MFA on user accounts"
  policy      = "${data.template_file.enable_mfa_policy.rendered}"
}

resource "aws_iam_group_policy_attachment" "webops-attach-enable-mfa" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "${aws_iam_policy.enable-mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "developers-attach-enable-mfa" {
  group      = "${aws_iam_group.developers.name}"
  policy_arn = "${aws_iam_policy.enable-mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "webops-attach-iam-password-change" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "developers-attach-iam-password-change" {
  group      = "${aws_iam_group.developers.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "webops-attach-administrator-access" {
  group      = "${aws_iam_group.webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
