aws_access_key    = "<Your AWS Access Key>"
aws_secret_key    = "<Your AWS Access Key>"

dns_domain        = "thyhum.com"
aws_region        = "us-east-1"
aws_instance_type = "t2.micro"
aws_subnet_cidr_newbits = 2

# Instance Name: CentOS 7
# For future enhancement, we can also use other OS, eg. Ubuntu 16.04
# default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64*"
aws_instance_name = "CentOS Linux 7 x86_64 HVM EBS 1801_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-0a537770.4"
aws_instance_connect_as = "centos"

tag_tf_id         = "mongodb"
hostname_prefix   = "mongodb-"
private_key_path  = "environments/mongodb"
public_key_path   = "environments/mongodb.pub"