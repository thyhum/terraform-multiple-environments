# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# DATA
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
data "aws_ami" "instance" {

  filter {
    name      = "name"
    values    = ["${var.aws_instance_name}"]
  }

  # Get the most recent AMI, just in case ${var.instance_name} returns more than one record
  most_recent = true

}

data "aws_availability_zones" "az" {}

data "aws_route53_zone" "dns_domain"{
  name = "${var.dns_domain}"
}
