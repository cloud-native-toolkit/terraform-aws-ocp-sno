locals {
  pull_secret = var.pull_secret_file != "" ? "${chomp(file(var.pull_secret_file))}" : var.pull_secret

  install_path = "${path.cwd}/${var.install_offset}"
  binary_path = "${path.cwd}/${var.binary_offset}"

  cluster_type = "openshift"
  cluster_type_code = "ocp4"
  cluster_version = "${data.external.cluster_info.result.serverVersion}_openshift"

  key_name = "ocp_access"  
}

resource "local_file" "aws_config" {
    content = templatefile("${path.module}/templates/credentials.tftpl",{
        ACCESS_KEY      = var.access_key
        ACCESS_SECRET   = var.secret_key
    })
    filename        = pathexpand("~/.aws/credentials")
    file_permission = "0600"
}

resource "tls_private_key" "key" {
    count     = var.public_ssh_key == "" ? 1 : 0

    algorithm = var.algorithm
    rsa_bits  = var.algorithm == "RSA" ? var.rsa_bits : null
    ecdsa_curve = var.algorithm == "ECDSA" ? var.ecdsa_curve : null
}

resource "local_file" "private_key" {
    count           = var.public_ssh_key == "" ? 1 : 0

    content         = tls_private_key.key[0].private_key_pem
    filename        = "${local.install_path}/${local.key_name}"
    file_permission = "0600"
}

resource "local_file" "public_key" {
    count           = var.public_ssh_key == "" ? 1 : 0
    
    content         = tls_private_key.key[0].public_key_openssh
    filename        = "${local.install_path}/${local.key_name}.pub"
    file_permission = "0644"
}

data "local_file" "pub_key" {
    count = var.public_ssh_key == "" ? 1 : 0
    depends_on = [
      local_file.public_key
    ]

    filename        = "${local.install_path}/${local.key_name}.pub"
}

module setup_clis {
    source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

    bin_dir = local.binary_path
    clis    = ["openshift-install-${var.openshift_version}","jq","yq4","oc"]
}

resource "local_file" "install_config" {
    content = templatefile("${path.module}/templates/install-config.yaml.tftpl", {
        BASE_DOMAIN             = var.base_domain_name
        HYPERTHREADING          = var.hyperthreading
        ARCHITECTURE            = var.architecture
        NODE_TYPE               = var.node_type
        VOLUME_IOPS             = var.volume_iops
        VOLUME_SIZE             = var.volume_size
        VOLUME_TYPE             = var.volume_type
        CLUSTER_NAME            = var.cluster_name
        CLUSTER_CIDR            = var.cluster_cidr
        CLUSTER_HOST_PREFIX     = var.cluster_host_prefix
        MACHINE_CIDR            = var.vpc_cidr
        NETWORK_TYPE            = var.network_type
        SERVICE_NETWORK_CIDR    = var.service_network_cidr
        AWS_REGION              = var.region
        RESOURCE_GROUP          = var.resource_group_name
        PRIVATE_SUBNET_ID       = var.private_subnet
        PUBLIC_SUBNET_ID        = var.public_subnet
        PULL_SECRET             = local.pull_secret
        PUBLISH                 = var.private ? "Internal" : "External"
        PUBLIC_SSH_KEY          = var.public_ssh_key == "" ? data.local_file.pub_key[0].content : var.public_ssh_key
    })
    filename        = "${local.install_path}/install-config.yaml"
    file_permission = "0664"
}

resource "null_resource" "openshift-install" {
  depends_on = [
        local_file.aws_config,
        local_file.install_config,
        module.setup_clis
  ]

  triggers = {
        binary_path = local.binary_path
        install_path = local.install_path
        debug = var.debug
  }

  provisioner "local-exec" {
    when = create

    command = "${path.module}/scripts/install.sh"

    environment = {
        BINARY_PATH = "${self.triggers.binary_path}"
        INSTALL_PATH = "${self.triggers.install_path}"
        LOG_LEVEL    = self.triggers.debug ? "debug" : "info"
     }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/destroy.sh"
    
    environment = {
        BINARY_PATH = "${self.triggers.binary_path}"
        INSTALL_PATH = "${self.triggers.install_path}"
        LOG_LEVEL    = self.triggers.debug ? "debug" : "info"
     }
  }
}

data external "cluster_info" {
    depends_on = [
        null_resource.openshift-install,
        module.setup_clis
    ]

    program = ["bash", "${path.module}/scripts/cluster-info.sh"]
    
    query = {
        bin_dir = local.binary_path
        log_file = "${local.install_path}/.openshift_install.log"
        metadata_file = "${local.install_path}/metadata.json"
        kubeconfig_file = "${local.install_path}/auth/kubeconfig"
    }
}

module "acme-cert-apps" {
    source = "github.com/cloud-native-toolkit/terraform-aws-acme-certificate?ref=v1.0.1"

    domain                  = "apps.${data.external.cluster_info.result.clusterDomain}"
    wildcard_domain         = true
    acme_registration_email = var.acme_registration_email
    aws_access_key          = var.access_key
    aws_secret_key          = var.secret_key
    testing                 = var.use_staging_certs ? true : false
    create_certificate      = var.update_ingress_cert ? var.byo_certs ? false : true : false
}

module "acme-cert-api" {
    source = "github.com/cloud-native-toolkit/terraform-aws-acme-certificate?ref=v1.0.1"

    domain                  = "api.${data.external.cluster_info.result.clusterDomain}"
    acme_registration_email = var.acme_registration_email
    aws_access_key          = var.access_key
    aws_secret_key          = var.secret_key
    testing                 = var.use_staging_certs ? true : false
    create_certificate      = var.update_ingress_cert ? var.byo_certs ? false : true : false
}

module "api-certs" {
    source = "github.com/cloud-native-toolkit/terraform-any-ocp-ipi-certs?ref=v1.0.2"
    count = var.update_ingress_cert ? 1 : 0

    apps_cert         = var.byo_certs ? file(var.apps-cert-file) : module.acme-cert-apps.cert
    apps_key          = var.byo_certs ? file(var.apps-key-file)  : module.acme-cert-apps.key
    apps_issuer_ca    = var.byo_certs ? file(var.apps-ca-file)   : module.acme-cert-apps.issuer_ca
    api_cert          = var.byo_certs ? file(var.api-cert-file)  : module.acme-cert-api.cert
    api_key           = var.byo_certs ? file(var.api-key-file)   : module.acme-cert-api.key
    api_issuer_ca     = var.byo_certs ? file(var.api-ca-file)    : module.acme-cert-api.issuer_ca
    bin_dir           = local.binary_path
    config_file_path  = "${local.install_path}/auth/kubeconfig"    
}