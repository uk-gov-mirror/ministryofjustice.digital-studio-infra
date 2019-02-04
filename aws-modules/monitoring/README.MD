# AWS Monitoring Module
Simple terraform module for deployment of monitoring infrastructure on Amazon Web Services (AWS).

----

### Why monitoring module? 
The aim of this module is to provide a structured approach for deployment of required monitoring infrastructure in a fully automated manner.

The infrastructure is used to display required CloudWatch metrics on the Grafana dashboards to provide insights into the current state of operations.  

### What is included?
The module was written to provide a full-stack deployment approach without a need to deploy any additional resources and reduce the number of pre-requisites.  

##### Components deployed

The module at the moment deploys:
- VPC
- Internet Gateway
- Public Subnet
- Network Access Control List (with VPN access)
- EC2 instance 
- EC2 Role (CloudWatch access)
- Security Group (with VPN access)
- IAM user
- IAM user access key
- IAM policy (CloudWatch access)
- DNS entries

### What pre-reqs are there? 
The aim of this module was to limit the number of pre-reqs required, which are:
- existing/active session to an AWS account
- existing/active session to an Azure Subscription
- active AWS EC2 keypair
- latest version of terraform (incl. AWS/Azure providers) 
- existing Azure DNS zone

### Module inputs 
The following variable inputs are required for the module deployment to function. 
` environment-name [string] ` - name of the environment you are deploying to e.g. prod
` key-pair-name [string] ` - name of existing ec2 keypair used to SSH into the instance
` application-name [string] ` - name of the application you are deploying, e.g. monitoring
` dns-zone-name [string] ` - name of the DNS zone where the DNS record will be created
` dns-zone-rg [string] ` - resource group of the DNS zone where the DNS record will be created

### Local Variables
The values of following local variables can be overriden: 
```default_vpc_ip_range``` -- IP range of the VPC, e.g. 192.168.0.0/25
``` default_subnet_ip_range ``` -- IP range of the public subnet, e.g. 192.168.0.0/25
``` allowed_inbound_ip  ``` -- allowed IP address of a primary office location
``` allowed_inbound_vpn_ip ``` -- allowed IP address of a secondary (OR remote) office location
``` default_ec2_instance_size ``` -- size of an instance to be deployed **(t2.small recommended)**
```default_availability_zone``` -- the AZ for the instance to be deplyed into

### Module outputs
To simplify management the following outputs have been introduced: 
- ```monitoring_ip``` - IP of an EC2 instance that can be used for management/Grafana access
- ```monitoring_dns_urls``` - URL of a DNS CNAME record and a public instance DNS name

### Current limitations, known issues and TODOs
The following issues and limitations have been found so far: 
- automated delivery of Grafana dashboards to an EC2 instance
- terraform stores the secret of IAM user in the state file, stored in a vault instead
- automated provisioning of key pair and store a vault
- allow deployment of DNS records in an AWS DNS management, e.g. Route53 if desired