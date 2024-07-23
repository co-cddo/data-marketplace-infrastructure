## Hosted zone
resource "aws_route53_zone" "datamarketplace" {
  name = "datamarketplace.gov.uk"
}


# Temporary test environments for DataMarketplace
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
    {
      name    = "_dnsauth.dev.dm.cddo.cabinetoffice.gov.uk"
      type    = "TXT"
      ttl     = 300
      records = [
        "_txz6jm5lfata4tivxix808iqp8sped6",
      ]
    },
  ]
}

# Datamarketplace
module "datamarketplace" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = "datamarketplace.gov.uk"

  records = [
    {
      name    = "dev"
      type    = "CNAME"
      ttl     = 300
      records = [
        "cddo-dev-bve6cnagahezfch0.a02.azurefd.net",
      ]
    },
    {
      name    = "_dnsauth.dev.datamarketplace.gov.uk"
      type    = "TXT"
      ttl     = 300
      records = [
        "_bsad0xqdw2no77r6246efdye9l9lygk",
      ]
    },
    {
      name    = "preview"
      type    = "CNAME"
      ttl     = 300
      records = [
        "cddo-production-dneqgkgqfnaxg2ds.a03.azurefd.net",
      ]
    },
    {
      name    = "_dnsauth.preview.datamarketplace.gov.uk"
      type    = "TXT"
      ttl     = 300
      records = [
        "_vyg83xw6n719deh710x50gty892dfkp",
      ]
    },
    {
      name    = "www"
      type    = "CNAME"
      ttl     = 300
      records = [
        "cddo-production-dneqgkgqfnaxg2ds.a03.azurefd.net",
      ]
    },
    {
      name    = "_dnsauth.datamarketplace.gov.uk"
      type    = "TXT"
      ttl     = 300
      records = [
        "_tycxv58rpzr8m9t16vqpzawvu54o2zc",
      ]
    },
  ]
}

