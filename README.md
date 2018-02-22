Terraform - multiple environments
========================
The goal of this repo is to show how we can safely and easily create, change and improve multiple environments infrastructure with Terraform. 

It supports multiple environments (eg. DEV, QA, UAT and PROD) using same Terraform configuration while maintaining consistencies between those environments, meaning each run on different environment will match the previous ones. 

As a sample, we deploy mongo 3.4 docker image. The focus is still on Terraform configuration managing AWS resources and trigerring Ansible to deploy application inside instances (Not much on MongoDB setting).

It is using AWS provider to understand the API to manage these resources:

* VPC
* Security Groups
* Elastic Block Store Volumes
* Route 53
* EC2 Instance

Terraform will continue with triggering ansible to configure the instances:
* Generate the inventory for number of instances which are dynamically created
* Run ansible-playbook locally

Ansible playbook will then take care of configuring the instances:
* Creating MongoDB DB PV/VG/LV on EBS disk
* Installing docker with all required packages (eg. Docker CE, docker-compose)
* Configuring MongoDB docker:
    * Expose MongoDB port (27017)
    * Bind DB Volumes to /data/db
    * Route Log message to syslog

It can be enhanced to support multi IaaS providers (eg. GCP/Azure, etc) and operating system (eg. Ubuntu); and even be integrated with other SaaS (eg. Cloudflare, DNS provider, etc).

#Requirements

##1. Tools
Ensure we have the following tools installed and activated (I have not verified whether or not there is any compatibility issue with different version):
* Terraform v0.11.3
    * provider.aws v1.9.0
    * provider.null v1.0.0
* Python v3.5.2
* Ansible v2.4.3.0

##2. Domain
* Create a zone in Route 53 (eg. thyhum.com) as main DNS domain  
    It'll be used as a data source in Terraform later. We don't configure it as a resource to prevent it being removed when we destroy our infrastructure :)  

    You can use existing zone too.

* Create NS records in your DNS server (eg. thyhum.com) to AWS NS servers, or point your domain Nameservers to AWS.  
    Optional, if you really want to connect to newly created instances using FQDN later:


# Environments

* Each resource will have a tag (Environment) where it's in
* Each instance's FQDN will be under <ENV>.your.domain, eg.
    * An instance in DEV-AP: mongo.dev-ap.thyhum.com 

#Terraform Variables

##Global 
Global variables are stored in _terraform.tfvars_. 
```hcl-terraform
aws_access_key   = "<Your AWS Access Key>"
aws_secret_key   = "<Your AWS Secret Key>"

dns_domain       = "thyhum.com"
```

##Environment
Environment variable is located in "**environment/<TF_ENV>/main.yml**".  

It will override variables defined in terraform.tfvars and variables with default value. As an example, in dev-ap environment, we use different DNS Domain and also define environment-specific variables (eg. Resource's environment tag, CIDR block, Region, etc):

```bash
$ cat environments/dev-ap/main.tfvars 
dns_domain = "thyhum.io"

tag_environment      = "thyhum"
aws_vpc_cidr_block   = "10.255.0.0/26"
aws_region           = "ap-southeast-2"
aws_az_count         = 3
mongodb_count        = 2
mongodb_ebs_vol_size = 1
```

Optionally, you can override other variables too (eg. using different set of SSH public/private keys).

##Sample Environments in this repo
Main DNS Domain: thyhum.com

* **dev-ap** (environment/dev-ap/main.tfvars)  
    Region: ap-southeast-2  
    AZ count: 3  
    MongoDB count: 2  
    EBS Volume size: 1GB  
    Sub-domain: dev-ap.thyhum.com  

* **dev-us** (environment/dev-us/main.tfvars)  
    Region: us-west-1  
    AZ count: 2 (at the time of writing, us-west-1 has two AZs)  
    MongoDB count: 3 (instances will be distributed to the two AZs)  
    EBS Volume size: 1GB  
    Sub-domain: dev-us.thyhum.com  

* **uat** (environment/uat/main.tfvars)  
    Region: us-east-1  
    AZ count: 3  
    MongoDB count: 3  
    EBS Volume size: 1TB  
    Sub-domain: uat.thyhum.com  

* **prod** (environment/prod/main.tfvars)  
    Region: us-east-1  
    AZ count: 6  
    MongoDB count: 6  
    EBS Volume size: 1TB  
    Sub-domain: prod.thyhum.com  

 
#Usage
##Initialize
As a start, go to the folder where terraform configuration files located. 

Run _terraform init_ to install all required plugins (aws and null). This command need to be run at the first-time after cloning from version control or adding a new provider in Terraform configuration.
 
```bash
$ terraform init
Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (1.9.0)...
- Downloading plugin for provider "null" (1.0.0)...

...<snip>...

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

Once you have initialized your working directory, we can continue with running Terraform on an environment using this command. For example, we want to manage *dev-ap* environment:

```bash
$ export TF_VAR_ENV=YOUR_ENV ; terraform apply -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars
```

Basically, we export an environment variable (TF_VAR_ENV) to let Terraform knows about where state and variable files located, and to reference it inside configuration.  

Alternatively, you can export the variable and keep running terraform command. 

```bash
$ export TF_VAR_ENV=YOUR_ENV
$ terraform apply -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars
$ terraform apply -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars
$ terraform apply -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars
```

I prefer the first option as I will always see what environment I'm working on.  

This command can be put in a wrapper script too, eg:
```bash
# Not implemented yet
$ ./terraform.multienv.sh dev-ap
```

##Create
Now let me show you how to create an environment.

Terraform v0.11.3 has merged *plan* to *apply* command, so we can safely run *terraform apply* to review it before performing the actions.

Specify the environment (eg. dev-ap) to `TF_VAR_ENV` followed by `terraform <action> <parameters>`. When you need to work on a different environment, just put it in `TF_VAR_ENV` variable and use the same Terraform command.

```bash
$ export TF_VAR_ENV=dev-ap ; terraform apply -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars 
data.aws_availability_zones.az: Refreshing state...
data.aws_ami.instance: Refreshing state...
data.aws_route53_zone.dns_domain: Refreshing state...
n execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + aws_ebs_volume.ebs_vol[0]
      id:                                        <computed>
      arn:                                       <computed>

...<snip>...

Plan: 23 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 

```

Here you review the changes and type **yes** to proceed.  

```bash
  Enter a value: yes

aws_vpc.vpc: Creating...
  assign_generated_ipv6_cidr_block: "" => "false"
  cidr_block:                       "" => "10.255.0.0/26"
  default_network_acl_id:           "" => "<computed>"
  default_route_table_id:           "" => "<computed>"
  default_security_group_id:        "" => "<computed>"
  dhcp_options_id:                  "" => "<computed>"
  enable_classiclink:               "" => "<computed>"
  enable_classiclink_dns_support:   "" => "<computed>"
  enable_dns_hostnames:             "" => "<computed>"
  enable_dns_support:               "" => "true"

...<snip>...  

null_resource.mongodb1: Provisioning with 'local-exec'...
null_resource.mongodb1 (local-exec): Executing: ["/bin/sh" "-c" "echo \"[mongodb]\n54.252.173.177\n13.210.150.99\n\" > environments/dev-ap/inventories\n\nansible-playbook ansible/mongodb.yml \\\n -i environments/dev-ap/inventories \\\n -u centos \\\n --key-file environments/xxxxxxxxx\n\n"]

null_resource.mongodb1 (local-exec): PLAY [Wait for ssh running on all instance] *************************************

null_resource.mongodb1 (local-exec): TASK [pause] *******************************************************************
null_resource.mongodb1 (local-exec): Pausing for 90 seconds
null_resource.mongodb1 (local-exec): (ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
aws_route53_zone.dns_environment: Still creating... (1m0s elapsed)

...<snip>...

null_resource.mongodb1: Creation complete after 3m37s (ID: XXXXXXXXXXXXXXXX)

Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:

MongoDB FQDNs (port: 27017) = [
    mongodb-0.dev-ap.thyhum.com,
    mongodb-1.dev-ap.thyhum.com
]


```

Test the connection to each instances

```bash
$ telnet mongodb-0.dev-ap.thyhum.com 27017
Trying 54.252.173.177...
Connected to mongodb-0.thyhum.d.thy.science.
Escape character is '^]'.
^]
telnet> q
Connection closed.

$ telnet mongodb-1.dev-ap.thyhum.com 27017
Trying 13.210.150.99...
Connected to mongodb-1.thyhum.d.thy.science.
Escape character is '^]'.
^]
telnet> q
Connection closed.

```

We have successfully deployed two MongoDB servers to dev-ap and verified the connectivity.  

##Destroy

Now I'm going to show you destroying dev-ap environment.  

It will remove all resources (Instances, Security Groups, EBS Volumes, etc)

```bash
$ export TF_VAR_ENV=dev-ap ; terraform destroy -state=environments/$TF_VAR_ENV/terraform.tfstate -var-file=environments/$TF_VAR_ENV/main.tfvars 
aws_vpc.vpc: Refreshing state... (ID: vpc-xxxxxxxx)
aws_key_pair.key_pair: Refreshing state... (ID: xxxxxxxx)
aws_route53_zone.dns_environment: Refreshing state... (ID: xxxxxxxx)
data.aws_route53_zone.dns_domain: Refreshing state...
data.aws_availability_zones.az: Refreshing state...
data.aws_ami.instance: Refreshing state...
aws_ebs_volume.ebs_vol[0]: Refreshing state... (ID: vol-xxxxxxxx)
aws_ebs_volume.ebs_vol[1]: Refreshing state... (ID: vol-xxxxxxxx)
aws_route53_record.dns_environment_ns: Refreshing state... (ID: xxxxxxxx)

...<snip>...

Terraform will perform the following actions:

  - aws_ebs_volume.ebs_vol[0]

  - aws_ebs_volume.ebs_vol[1]

  - aws_instance.mongodb1[0]

  - aws_instance.mongodb1[1]

  - aws_internet_gateway.igw

  - aws_key_pair.key_pair

  - aws_route53_record.dns_environment_ns

  - aws_route53_record.mongodb1[0]

...<snip>...

Plan: 0 to add, 0 to change, 23 to destroy.

Do you really want to destroy?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

null_resource.mongodb1: Destroying... (ID: xxxxxxxx)
null_resource.mongodb1: Destruction complete after 0s
aws_route53_record.mongodb1[1]: Destroying... (ID: xxxxxxxx)
aws_route53_record.dns_environment_ns: Destroying... (ID: xxxxxxxx)
aws_route53_record.mongodb1[0]: Destroying... (ID: xxxxxxxx)
aws_volume_attachment.vol_attach[0]: Destroying... (ID: xxxxxxxx)
aws_route_table_association.rta[0]: Destroying... (ID: xxxxxxxx)
aws_route_table_association.rta[2]: Destroying... (ID: xxxxxxxx)
aws_route_table_association.rta[1]: Destroying... (ID: xxxxxxxx)
aws_volume_attachment.vol_attach[1]: Destroying... (ID: xxxxxxxx)
aws_route_table_association.rta[2]: Destruction complete after 1s
aws_route_table_association.rta[1]: Destruction complete after 1s
aws_route_table_association.rta[0]: Destruction complete after 1s
aws_route_table.route_table: Destroying... (ID: xxxxxxxx)

...<snip>...

Destroy complete! Resources: 23 destroyed.
```
