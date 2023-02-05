variable "region" {
  description = "AWS region to deploy cluster"
  type        = string
}

variable "access_key" {
  description = "AWS account access key"
  type        = string
}

variable "secret_key" {
  description = "AWS account secret key"
  type        = string
}

variable "base_domain_name" {
  description = "Base domain name (e.g. myclusters.mydomain.com)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster that prefixes the domain name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the environment tag (default = \"Default\")"
  type        = string
  default     = "Default"
}

// One of the below variables (either pull secret or pull secret file) need to be set

variable "pull_secret" {
    description = "Pull secret for OpenShift image repository access and to register the cluster"
    type        = string
    default     = ""
}

variable "pull_secret_file" {
    description = "File with the pull secret for OpenShift image repository access and to register the cluster"
    type        = string
    default     = ""
}

// Following variables are for the existing VPC (required)
// It is possible for the installer to create a new VPC and infrastructure resources, however,
// this creates 3 NAT gateways on 3 sets of subnets of which only one is used with this single node deployment.

variable "vpc_cidr" {
  description   = "CIDR of the existing VPC"
  type          = string
}

variable "private_subnet" {
  description   = "Existing private subnet name"
  type          = string
}

variable "public_subnet" {
  description   = "Existing public subnet name"
  type          = string
}

// If not defined, an SSH key pair will be generated for node access post implementation

variable "public_ssh_key" {
  description = "The SSH Public Key to use for OpenShift Installation"
  type        = string
  default     = ""
}

// Following are the defaults if creating a new key pair

variable "algorithm" {
    description = "Algorithim to be utilized if creating a new key (RSA, ECDSA or ED25519, default = RSA)"
    type        = string
    default     = "RSA"
}

variable "rsa_bits" {
    description = "Number of bits to use for RSA key (default = 4096)"
    type        = number
    default     = 4096
}

variable "ecdsa_curve" {
    description = "ECDSA Curve value to be utilized for ECDSA key (P224, P256, P521, default = P224)"
    type        = string
    default     = "P224"
}

// BYO Certificate values if using
variable "apps-cert-file" {
    description = "File containing the apps (*.apps.cluster.domain) certificate."
    type        = string
    default     = ""
}

variable "apps-key-file" {
    description = "File containing the apps (*.apps.cluster.domain) private key."
    type        = string
    default     = ""
}

variable "apps-ca-file" {
    description = "File containing the apps (*.apps.cluster.domain) certificate authority bundle."
    type        = string
    default     = ""
}

variable "api-cert-file" {
    description = "File containing the api (api.cluster.domain) certificate."
    type        = string
    default     = ""
}

variable "api-key-file" {
    description = "File containing the api (api.cluster.domain) private key."
    type        = string
    default     = ""
}

variable "api-ca-file" {
    description = "File containing the api (api.cluster.domain) certificate authority bundle."
    type        = string
    default     = ""
}

// Variables below this have default values

variable "update_ingress_cert" {
  description = "Flag to indicate whether to update the ingress certificates after clusetr creation (default = \"true\")"
  type        = bool
  default     = true
}

variable "private" {
  description = "Flag to indicate whether the cluster is for a private cluster (default = \"false\")"
  type        = bool
  default     = false
}

variable "byo_certs" {
  description = "Flag to indicate whether to use BYO certificates instead of creating new ones (default = \"false\")"
  type        = bool
  default     = false
}

variable "acme_registration_email" {
  description = "Valid email for registration of LetsEncrypt certificate. This must be changed if creating ingress certificates."
  type        = string
  default     = "me@mydomain.com"
}

variable "use_staging_certs" {
  description = "Flag to indicate whether to generate staging or valid certificates. Used for testing. Note quota limits on valid LetsEncrypt certificates. (default = \"false\")"
  type        = bool
  default     = false
}

variable "binary_offset" {
  description = "Path offset from current directory to store binaries"
  type        = string
  default     = "binaries"
}

variable "install_offset" {
    description = "Path offset from current working directory for install metadata (default = install)"
    type        = string
    default     = "install"
}

variable "openshift_version" {
  description = "OpenShift version to install"
  type        = string
  default     = "4.10"
  validation {
    condition = (
        substr(var.openshift_version, 0 , 2) == "4."
    )
    error_message = "Openshift version must be either \"4.x\" or \"4.x.x\"."
  } 
}

variable "hyperthreading" {
  description   = "Enable hyperthreading for node (default = \"Enabled\")"
  type          = string
  default       = "Enabled"
}

variable "architecture" {
  description   = "CPU architecture for node (default = \"amd64\")"
  type          = string
  default       = "amd64"
}

variable "node_type" {
  description   = "AWS instance type for node (default = \"m6i.4xlarge\")"
  type          = string
  default       = "m6i.4xlarge"
}

variable "volume_iops" {
  description = "Disk IOPS (default = 400)"
  type = string
  default = 400
}

variable "volume_size" {
  description = "Compute/worker node disk size in GB (default = 500)"
  type        = string
  default     = 500
}

variable "volume_type" {
  description = "Type of disk for the node [standard io1 gp2 gp3 sc1 st1] (default = \"io1\")"
  type        = string
  default     = "io1"
}

variable "cluster_cidr" {
  description = "CIDR for the internal OpenShift network (default = 10.128.0.0/14)"
  type        = string
  default     = "10.128.0.0/14"
}

variable "cluster_host_prefix" {
  description = "Host prefix for internal OpenShift network (default = 23)"
  type        = string
  default     = 23
}

variable "network_type" {
  description = "Type of software defined networking for internal OpenShift (default = \"OpenShiftSDN\")"
  type = string
  default = "OpenShiftSDN"
}

variable "service_network_cidr" {
  description = "CIDR for the internal OpenShift service network (default = 172.30.0.0/16)"
  type        = string
  default     = "172.30.0.0/16"
}

variable "debug" {
  description = "Flag to indicate whether debug information is required for build"
  type        = bool
  default     = false
}

