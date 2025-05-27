
# for_each  - https://www.terraform.io/docs/language/meta-arguments/for_each.html
# lifecycle - https://www.terraform.io/docs/language/meta-arguments/lifecycle.html

resource "aws_ssm_parameter" "string_parameters" {
  for_each  = toset(local.string_parameters)
  name      = "${local.prefix}${each.value}"
  type      = "String"
  value     = local.string_initial_value
  tier      = local.string_tier
  overwrite = local.overwrite
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


resource "aws_ssm_parameter" "securestring_parameters" {
  for_each = toset(local.securestring_parameters)
  name     = "${local.prefix}${each.value}"
  type     = "SecureString"
  value    = local.securestring_initial_value
  tier     = local.securestring_tier
  key_id   = local.key_id
  #  overwrite = local.overwrite
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


resource "aws_ssm_parameter" "stringlist_parameters" {
  for_each  = toset(local.stringlist_parameters)
  name      = "${local.prefix}${each.value}"
  type      = "StringList"
  value     = local.stringlist_initial_value
  tier      = local.stringlist_tier
  overwrite = local.overwrite
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

data "aws_ssm_parameter" "env-vardata" {
  name = "/dm/dev/config-inputs-json"
}

resource "aws_ssm_parameter" "securestring_config_parameters" {
  for_each  = toset(local.securestring_config_parameters)
  name      = "${local.prefix}${each.value}"
  type      = "SecureString"
  value     = templatefile("${path.module}/../../app-fast/config/templates/dm-fast-api-config.tftpl",
    {
    DOMAIN_NAME                                          =jsondecode(data.aws_ssm_parameter.env-vardata.value)["DOMAIN_NAME"],
    SSO_CLIENT_ID                                        =jsondecode(data.aws_ssm_parameter.env-vardata.value)["SSO_CLIENT_ID"],
    SSO_CLIENT_SECRET                                    =jsondecode(data.aws_ssm_parameter.env-vardata.value)["SSO_CLIENT_SECRET"],
    MS_DBSERVER                                          =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_DBSERVER"],
    MS_PORT                                              =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_PORT"],
    MS_DATABASE_SHARE                                    =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_DATABASE_SHARE"],
    MS_DATABASE_USERS                                    =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_DATABASE_USERS"],
    MS_TRUSTSVRCERT                                      =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_TRUSTSVRCERT"],
    PG_DBSERVER                                          =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_DBSERVER"],
    PG_PORT                                              =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_PORT"],
    PG_DATABASE                                          =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_DATABASE"],
    PG_USERID                                            =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_USERID"],
    PG_PW                                                =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_PW"],
    MS_USERID                                            =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_USERID"],
    MS_PW                                                =jsondecode(data.aws_ssm_parameter.env-vardata.value)["MS_PW"],
    SECRETKEY                                            =jsondecode(data.aws_ssm_parameter.env-vardata.value)["SECRETKEY"],
    AUDIENCES                                            =jsondecode(data.aws_ssm_parameter.env-vardata.value)["AUDIENCES"],
    GOV_NOTIFY_API_KEY                                   =jsondecode(data.aws_ssm_parameter.env-vardata.value)["GOV_NOTIFY_API_KEY"],
    NEW_DATA_SHARE_REQUEST_RECEIVED_TEMPLATE_ID          =jsondecode(data.aws_ssm_parameter.env-vardata.value)["NEW_DATA_SHARE_REQUEST_RECEIVED_TEMPLATE_ID"],
    DATA_SHARE_REQUEST_CANCELLED_TEMPLATE_ID             =jsondecode(data.aws_ssm_parameter.env-vardata.value)["DATA_SHARE_REQUEST_CANCELLED_TEMPLATE_ID"],
    DATA_SHARE_REQUEST_ACCEPTED_TEMPLATE_ID              =jsondecode(data.aws_ssm_parameter.env-vardata.value)["DATA_SHARE_REQUEST_ACCEPTED_TEMPLATE_ID"],
    DATA_SHARE_REQUEST_REJECTED_TEMPLATE_ID              =jsondecode(data.aws_ssm_parameter.env-vardata.value)["DATA_SHARE_REQUEST_REJECTED_TEMPLATE_ID"],
    DATA_SHARE_REQUEST_RETURNED_WITH_COMMENTS_TEMPLATE_ID=jsondecode(data.aws_ssm_parameter.env-vardata.value)["DATA_SHARE_REQUEST_RETURNED_WITH_COMMENTS_TEMPLATE_ID"],
    WELCOMETEMPLATE                                      =jsondecode(data.aws_ssm_parameter.env-vardata.value)["WELCOMETEMPLATE"],
    PG_DATABASE_URL                                      =jsondecode(data.aws_ssm_parameter.env-vardata.value)["PG_DATABASE_URL"],
    GOOGLE_CLIENT_ID                                     =jsondecode(data.aws_ssm_parameter.env-vardata.value)["GOOGLE_CLIENT_ID"],
    GOOGLE_CLIENT_SECRET                                 =jsondecode(data.aws_ssm_parameter.env-vardata.value)["GOOGLE_CLIENT_SECRET"],
    RACK_ENV                                             =jsondecode(data.aws_ssm_parameter.env-vardata.value)["RACK_ENV"],
    RAILS_ENV                                            =jsondecode(data.aws_ssm_parameter.env-vardata.value)["RAILS_ENV"],
    SECRET_KEY_BASE                                      =jsondecode(data.aws_ssm_parameter.env-vardata.value)["SECRET_KEY_BASE"],
    })
  tier      = local.securestring_tier
  key_id    = local.key_id
#  overwrite = local.overwrite
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
