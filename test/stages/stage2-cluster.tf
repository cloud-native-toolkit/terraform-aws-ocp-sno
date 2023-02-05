module "cluster" {
  source = "./module"

  region                = var.region
  access_key            = var.access_key
  secret_key            = var.secret_key
  base_domain_name      = var.base_domain_name
  cluster_name          = "${var.name_prefix}-${random_string.cluster_id.result}"
  resource_group_name   = var.resource_group
  pull_secret_file      = var.pull_secret
  private_subnet        = module.private_subnet.ids[0]
  public_subnet         = module.public_subnet.ids[0]
  vpc_cidr              = module.vpc.vpc_cidr
  private               = false
  use_staging_certs     = true
  openshift_version     = "4.10"
  debug                 = true
}