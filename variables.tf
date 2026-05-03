variable "subscription_id" {
  description = "(Required) The Subscription ID."
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

variable "workload_name" {
  description = "(Required) The name of the workload."
  type        = string
}

variable "allowed_public_ip_address_ranges" {
  description = "(Optional) The external IP address ranges allowed to access the Azure resources."
  type        = list(string)
  default     = []
}

variable "nginx_internal_load_balancer_ip" {
  description = "(Optional) The IP address of the Kubernetes Service of NGINX Ingress Controller."
  type        = string
  default     = "1.2.3.4"
}

variable "haproxy_internal_load_balancer_ip" {
  description = "(Optional) The IP address of the Kubernetes Service of HAProxy Ingress Controller."
  type        = string
  default     = "1.2.3.4"
}
