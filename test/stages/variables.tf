variable "name_prefix" {
  type = string
  description = "Prefix for resources"
}

variable "region" {
  type = string
  description = "AWS Region into which to deploy resources"
}

variable "resource_group_name" {
  type = string
  description = "Name for \"ResourceGroup\" tag on all resources"
}

variable "access_key" {
  type = string
  description = "AWS CLI Access Key"
}

variable "secret_key" {
  type = string
  description = "AWS CLI Secret Key"
}

variable "pull_secret" {
  type = string
  description = "Red Hat OpenShift Pull Secret"
}