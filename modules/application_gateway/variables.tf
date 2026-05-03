variable "resource_group_name" {
  description = "(Required) The name of the Resource Group."
  type        = string
}

variable "location" {
  description = "(Required) The location of the Azure resources (e.g. westeurope)."
  type        = string
}

variable "location_abbreviation" {
  description = "(Required) The location abbreviation (e.g. weu)."
  type        = string
}

variable "environment" {
  description = "(Required) The environment name (e.g. test)."
  type        = string
}

variable "type" {
  description = "(Required) The name of the Ingress Controller the Application Gateway is associated to."
  type        = string
}

variable "vnet_subnet_id" {
  description = "(Required) The ID of a Subnet where the Application Gateway should exist."
  type        = string
}

variable "internal_load_balancer_ip" {
  description = "(Required) The External IP address of the Ingress Controller Kubernetes Service."
  type        = string
}

variable "host_name" {
  description = "(Required) The hostname of the web application."
  type        = string
}

variable "tags" {
  description = "(Optional) The Tags for the Azure resources."
  type        = map(string)
  default     = {}
}
