## Hosted zone
variable "domain_name" {
  default = "datamarketplace.gov.uk"
}

resource "aws_route53_zone" "datamarketplace" {
  name = var.domain_name
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

resource "aws_route53_record" "dev-cname" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "dev"
  type    = "CNAME"
  ttl     = 300
  records = ["cddo-dev-bve6cnagahezfch0.a02.azurefd.net"]
}
resource "aws_route53_record" "dev-txt" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "_dnsauth.dev"
  type    = "TXT"
  ttl     = 300
  records = ["_p66t5uybni3hzxpa6hg4sct6iaowl2n"]
}

resource "aws_route53_record" "test-cname" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "test"
  type    = "CNAME"
  ttl     = 300
  records = ["cddo-test-f5g3gugzffgba3et.a02.azurefd.net"]
}
resource "aws_route53_record" "test-txt" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "_dnsauth.test"
  type    = "TXT"
  ttl     = 300
  records = ["_2e9i57q84sztg6d6pptoozfmsmt6xgf"]
}

resource "aws_route53_record" "prev-cname" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "preview"
  type    = "CNAME"
  ttl     = 300
  records = ["cddo-production-preview-gxhhc2cte4fpcnd2.a03.azurefd.net"]
}
resource "aws_route53_record" "prev-txt" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "_dnsauth.preview"
  type    = "TXT"
  ttl     = 300
  records = ["_mmunqo9xxjel1981uwpbvre4ahw924l"]
}

resource "aws_route53_record" "prod-cname" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["cddo-production-dneqgkgqfnaxg2ds.a03.azurefd.net"]
}
resource "aws_route53_record" "prod-txt" {
  zone_id = aws_route53_zone.datamarketplace.zone_id
  name    = "_dnsauth.www"
  type    = "TXT"
  ttl     = 300
  records = ["_nrkkr1fctcisn0s9fyj77gyqa2u392m"]
}

