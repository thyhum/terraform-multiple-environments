# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables - AWS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}
variable "aws_instance_type" {}
variable "aws_instance_name" {}
variable "aws_instance_connect_as" {}
variable "aws_vpc_cidr_block" {}
variable "aws_subnet_cidr_newbits" {}
variable "aws_az_count" {}
variable "mongodb_count" {}
variable "mongodb_ebs_vol_size" {}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Variables - Site
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
variable "ENV" {}
variable "tag_environment" {}
variable "dns_domain" {}
variable "hostname_prefix" {}
variable "tag_tf_id" {}
variable "public_key_path" {}
variable "private_key_path" {}




