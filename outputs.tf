output "id" {
    value       = data.external.cluster_info.result.clusterID
    description = "ID of the cluster"
}

output "name" {
    value       = var.cluster_name
    description = "Name of the cluster"
    depends_on = [
      data.external.cluster_info
    ]
}

output "resource_group_name" {
    value = var.resource_group_name
    description = "Tag for deployed resources"
    depends_on = [
      data.external.cluster_info
    ]
}

output "region" {
    value = var.region
    description = "AWS location containing the cluster"
    depends_on = [
      data.external.cluster_info
    ]
}

output "config_file_path" {
    value = "${local.install_path}/auth/kubeconfig"
    description = "Path to the config file for the cluster"
    depends_on = [
      data.external.cluster_info
    ]
}

output "consoleURL" {
    value = data.external.cluster_info.result.consoleURL
    description = "URL for the cluster console"
}

output "serverURL" {
    value = data.external.cluster_info.result.serverURL
    description = "The URL used to connect to the api of the cluster"
}

output "username" {
    value = data.external.cluster_info.result.kubeadminUsername
    description = "Administrator username for the cluster"
}

output "password" {
    value = data.external.cluster_info.result.kubeadminPassword
    description = "Administrator password for the cluster"
    sensitive = true
}

output "token" {
    value = data.external.cluster_info.result.serverToken
    description = "The admin user token used to generate the cluster"
    sensitive = true
}

output "bin_dir" {
    value = local.binary_path
    description = "Path to the client binaries"
}

output "platform" {
    value = {
        id = data.external.cluster_info.result.clusterID
        kubeconfig = "${local.install_path}/auth/kubeconfig"
        server_url = data.external.cluster_info.result.serverURL
        type = local.cluster_type
        type_code = local.cluster_type_code
        version = local.cluster_version
        ingress = data.external.cluster_info.result.consoleURL
        tls_secret = data.external.cluster_info.result.serverToken
    }
    sensitive = true
    description = "Configuration values for the created cluster"
    depends_on = [
      data.external.cluster_info
    ]
}