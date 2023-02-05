# AWS Single Node OpenShift IPI

## Module Overview

This module creates an OpenShift cluster on Amazon Web Services (AWS) using Installer-Provisioned Infrastructure. As such, it interfaces to AWS to create the infrastructure components, such as EC2 instances, for the cluster. It can either create all the infrastructure components including VPC and subnets for a quickstart, or in future, it will support providing an existing VPC environment. The deployed cluster will be across 3 availability zones.

This module is a cut down version of the full AWS OCP IPI module which is available [here](https://github.com/cloud-native-toolkit/terraform-aws-ocp-ipi)

### Prerequisites

1. A public domain needs to be configured in Route 53 which will be used by the cluster
1. The target region must have quota available for an additional VPC with 1 elastic IP and a NAT gateway.

### Software Dependencies

This module depends upon the following software components:

#### Command Line Tools
 - terraform >= 1.2.6

#### Terraform providers

- AWS provider >= v4.27.0

### Module Dependencies - new virtual network

When creating a new virtual network, this module has not dependencies on other modules.

### Module Dependencies - existing virtual network
Will be supported in a future release

## Input Variables

This module has the following input variables:
| Variable | Mandatory / Optional | Default Value | Description |
| -------------------------------- | --------------| ------------------ | ----------------------------------------------------------------------------- |
| cluster_name | Mandatory |  | The name to give the OpenShift cluster  |
| base_domain_name | Mandatory |  | The existing Route 53 wildcard base domain name that has been defined. For example, clusters.mydomain.com. |
| region | Mandatory |  | AWS region into which to deploy the OpenShift cluster |
| access_key | Mandatory |  | The AWS account access key |
| secret_key | Mandatory |  | The AWS account secret key |
| pull_secret | Mandatory | "" | The Red Hat pull secret to access the Red Hat image repositories to install OpenShift. One of pull_secret or pull_secret_file is required. |
| pull_secret_file | Mandatory | "" | The full path and name of the file containing the Red Hat pull secret to access the Red Hat image repositories for the OpenShift installation. One of pull_secret or pull_secret_file is required. |
| vpc_cidr | Mandatory |  | Exisitng VPC CIDR  |
| private_subnet | Mandatory |  | Existing private subnet in availability zone 1  |
| public_subnet | Mandatory |  | Existing public subnet in availability zone 1 (Set to empty string if making private only) |
| public_ssh_key | Optional | "" | An existing public key to be used for post implementation node (EC2 Instance) access. If left as default, a new key pair will be generated. |
| algorithm | Optional | RSA | Algorithm to be utilized if creating a new key |
| rsa_bits | Optional | 4096 | The number of bits for the RSA key if creating a new RSA key |
| ecdsa_curve | Optional | P224 | The ECDSA curve value to be utilized if creating a new ECDSA key |
| private | Optional | false | Flag to indicate whether cluster should be provisioned with private endpoints only (no internet access) |
| update_ingress_cert | Optional | true | Flag to indicate whether to update the ingress certificates after the cluster has been created |
| byo_certs | Optional | false | Flag to indicate whether to use BYO ingress certificates or create new ones |
| acme_registration_email | Optional | me@mydomain.com | Valid email address for certificate registration |
| use_staging_certs | Optional | false | Flag to indicate whether to generate staging or valid certificates. Used for testing. Note quota limits on valid certificates. |
| apps-cert-file | Optional | "" | If using BYO certificates, the full path to the file containing the apps (*.apps.cluster.domain) certificate |
| apps-key-file | Optional | "" | If using BYO certificates, the full path to the file containing the apps (*.apps.cluster.domain) private key |
| apps-ca-file | Optional | "" | If using BYO certificates, the full path to the file containing the apps (*.apps.cluster.domain) certificate authority bundle |
| api-cert-file | Optional | "" | If using BYO certificates, the full path to the file containing the api (*.api.cluster.domain) certificate |
| api-key-file | Optional | "" | If using BYO certificates, the full path to the file containing the api (*.api.cluster.domain) private key |
| api-ca-file | Optional | "" | If using BYO certificates, the full path to the file containing the api (*.api.cluster.domain) certificate authority bundle |
| binary_offset | Optional | binaries | The path offset from the terraform root directory into which the binaries will be stored. |
| install_offset | Optional | install | The path offset from the terraform root directory into which the OpenShift installation files will be stored. |
| openshift_version | Optional | 4.10 | The version of OpenShift to be installed (must be available in the mirror repository - see below) |
| hyperthreading | Optional | Enabled | Flag to determine whether hyperthreading should be used for master |
| architecture | Optional | amd64 | CPU Architecture for the worker nodes |
| node_type | Optional | m6i.4xlarge | AWS EC2 Instance type for the node. Note the minimum size is 4 vCPU and 16GB RAM |
| volume_iops | Optional | 400 | Node disk IOPS |
| volume_size | Optional | 500 | Node disk size (GB) |
| volume_type | Optional | io1 | Type of disk for worker nodes |
| cluster_cidr | Optional | 10.128.0.0/14 | CIDR for the internal OpenShift network. |
| cluster_host_prefix | Optional | 23 | Host prefix for the internal OpenShift network |
| network_type | Optional | OpenShiftSDN | Network plugin to use for the OpenShift virtual networking. |
| machine_cidr | Optional | 10.0.0.0/16 | CIDR for the master and worker nodes. Must be the same or a subset of the VPC CIDR |
| service_network_cidr | Optional | 172.30.0.0/16 | CIDR for the internal OpenShift service network. |

## Example Usage 
```hcl-terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

  }
}

provider "aws" {
  region        = var.region
  access_key    = var.access_key
  secret_key    = var.secret_key
}

# VPC and internet gateway 
module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-aws-vpc?ref=v1.6.0"

  provision             = true
  internal_cidr         = "10.0.0.0/20"
  name_prefix           = var.name_prefix
  resource_group_name   = var.resource_group_name
}

module "igw" {
  source = "github.com/cloud-native-toolkit/terraform-aws-vpc-gateways?ref=v1.2.1"

  name_prefix           = var.name_prefix
  provision             = true
  resource_group_name   = var.resource_group_name
  vpc_name              = module.vpc.vpc_name
}

# Subnets - 1 public, 1 private
module "public_subnet" {
  source = "github.com/cloud-native-toolkit/terraform-aws-vpc-subnets?ref=v2.3.0"

  name_prefix           = var.name_prefix
  provision             = true
  region                = var.region
  resource_group_name   = var.resource_group_name
  vpc_name              = module.vpc.vpc_name
  gateways              = module.igw.ids
  label                 = "public"
  multi-zone            = false
  subnet_cidrs          = ["10.0.1.0/24"]
  acl_rules             = []
  availability_zones    = []
}
module "private_subnet" {
  source = "github.com/cloud-native-toolkit/terraform-aws-vpc-subnets?ref=v2.3.0"

  name_prefix           = var.name_prefix
  provision             = true
  region                = var.region
  resource_group_name   = var.resource_group_name
  vpc_name              = module.vpc.vpc_name
  gateways              = module.ngw.ids
  label                 = "private"
  multi-zone            = false
  subnet_cidrs          = ["10.0.2.0/24"]
  acl_rules             = []
  availability_zones    = []
}

# NAT Gateway
module "ngw" {
  source = "github.com/cloud-native-toolkit/terraform-aws-nat-gateway?ref=v1.1.1"

  _count                = 1
  name_prefix           = var.name_prefix
  provision             = true
  resource_group_name   = var.resource_group_name
  subnet_ids            = module.public_subnet.subnet_ids
}

module "openshift-cluster" {
    source = "github.com/cloud-native-toolkit/terraform-aws-ocp-sno"

    region                = var.region
    access_key            = var.access_key
    secret_key            = var.secret_key
    base_domain_name      = var.base_domain_name
    cluster_name          = var.cluster_name
    resource_group_name   = var.resource_group_name
    pull_secret_file      = var.pull_secret
    private_subnet        = module.private_subnet.ids[0]
    public_subnet         = module.public_subnet.ids[0]
    vpc_cidr              = module.vpc.vpc_cidr
    private               = false
    openshift_version     = "4.10"
```

## Post Installation

Post installation it is necessary to add your own certificate to the cluster to access the console.

To access the cluster from the command line (this is using the default binary and install path offsets),
```
  $ export KUBECONFIG=./install/auth/kubeconfig
  $ ./binaries/oc get nodes
```

## Troubleshooting

In the event that the openshift installation fails, check the logs under,
```
<root_path>/<install_path>/.openshift_install.log
```
the default install_path value is install, so from the place you ran the terraform from, it is possible to see the last log entries using the following command,
```shell
$ tail -25 ./install/.openshift_install.log
```

The default kubeconfig for cluster access is located under the same installation directory,
```
<root_path>/<install_path>/auth/kubeconfig
```

To login to the cluster from the CLI, export this as your KUBECONFIG shell environment value,
```shell
$ export KUBECONFIG=./install/auth/kubeconfig
```

You should then be able to obtain details of the cluster, such as (with the default binary path),
```shell
$ ./binaries/oc get clusterversion
```
