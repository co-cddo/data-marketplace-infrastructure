module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = "dm.cddo.cabinetoffice.gov.uk"

  records = [
    {
      name    = "int"
      type    = "CNAME"
      ttl     = 300
      records = [
        "cddo-ui-test-staging-ekf2dzdzg3g5aeh6.z02.azurefd.net",
      ]
    },
    {
      name    = "test"
      type    = "CNAME"
      ttl     = 300
      records = [
        "cddo-test-f5g3gugzffgba3et.z02.azurefd.net",
      ]
    },
  ]
}
