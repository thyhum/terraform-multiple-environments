# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Providers
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
provider "aws" {
  access_key    = "${var.aws_access_key}"
  secret_key    = "${var.aws_secret_key}"
  region        = "${var.aws_region}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VPC
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_vpc" "vpc" {
  cidr_block  = "${var.aws_vpc_cidr_block}"

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_subnet" "subnet" {
  count                   = "${var.aws_az_count}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(var.aws_vpc_cidr_block, var.aws_subnet_cidr_newbits, count.index)}"
  availability_zone       = "${data.aws_availability_zones.az.names[count.index]}"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}-${count.index}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }

}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}-${count.index}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = "${var.aws_az_count}"
  route_table_id = "${aws_route_table.route_table.id}"
  subnet_id      = "${element(aws_subnet.subnet.*.id,count.index)}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Security groups
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_security_group" "SSH" {
  name   = "SSH"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_security_group" "MongoDB" {
  name   = "MongoDB"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# EBS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_ebs_volume" "ebs_vol" {
  count             = "${var.mongodb_count}"
  size              = "${var.mongodb_ebs_vol_size}"
  availability_zone = "${data.aws_availability_zones.az.names[count.index % var.aws_az_count]}"
  type              = "gp2"

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}-${count.index}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}
resource "aws_volume_attachment" "vol_attach" {
  count       = "${var.mongodb_count}"
  device_name = "/dev/xvdh"
  instance_id = "${element(aws_instance.mongodb1.*.id, count.index)}"
  volume_id   = "${element(aws_ebs_volume.ebs_vol.*.id, count.index)}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Route 53
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_route53_zone" "dns_environment" {
  name = "${var.tag_environment}.${var.dns_domain}"

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }

}
// Add dns_environment's NS records to the main domain (dns_domain)
resource "aws_route53_record" "dns_environment_ns" {
  zone_id = "${data.aws_route53_zone.dns_domain.id}"
  name    = "${var.tag_environment}.${var.dns_domain}"
  type    = "NS"
  ttl     = 60
  records = [
    "${aws_route53_zone.dns_environment.name_servers}"
  ]
}

resource "aws_route53_record" "mongodb1" {
  count     = "${var.mongodb_count}"
  name      = "${var.hostname_prefix}${count.index}"
  type      = "A"
  ttl       = 60
  zone_id   = "${aws_route53_zone.dns_environment.id}"
  records   = ["${element(aws_instance.mongodb1.*.public_ip, count.index)}"]
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Key Pair
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.tag_tf_id}-${var.tag_environment}"
  public_key = "${file(var.public_key_path)}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instance
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "aws_instance" "mongodb1" {
  count                  = "${var.mongodb_count}"
  ami                    = "${data.aws_ami.instance.id}"
  instance_type          = "${var.aws_instance_type}"
  subnet_id              = "${element(aws_subnet.subnet.*.id, count.index % var.aws_az_count)}"
  key_name               = "${aws_key_pair.key_pair.id}"
  vpc_security_group_ids = [
    "${aws_security_group.SSH.id}",
    "${aws_security_group.MongoDB.id}"
  ]

  root_block_device {
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags {
    Name        = "${var.tag_tf_id}-${var.tag_environment}-${count.index}"
    TF_ID       = "${var.tag_tf_id}"
    Environment = "${var.tag_environment}"
  }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Provisioner - local-exec ansible-playbook
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
resource "null_resource" "mongodb1" {
  # Trigger the provision
  triggers {
    host_id = "${join(",", aws_instance.mongodb1.*.id)}"
  }

  # Add all Public IP to inventories and run ansible-playbook
  provisioner "local-exec" {
    command = <<EOF
echo "[mongodb]
${join("\n", aws_instance.mongodb1.*.public_ip)}
" > environments/${var.ENV}/inventories

ansible-playbook ansible/mongodb.yml \
 -i environments/${var.ENV}/inventories \
 -u ${var.aws_instance_connect_as} \
 --key-file ${var.private_key_path}

EOF

  }
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
output "MongoDB FQDNs (port: 27017)" {
  value = "${aws_route53_record.mongodb1.*.fqdn}"
}