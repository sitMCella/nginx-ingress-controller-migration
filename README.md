# NGINX Ingress Controller Migration

## Table of contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [Terraform](#terraform)
* [Helm](#helm)
* [Migration](#migration)
* [Cleanup](#cleanup)

## Introduction

The following project provides an example procedure for migrating the NGINX Ingress Controller in Azure Kubernetes Service cluster to HAProxy Ingress Controller.

## Requirements

- Terraform
- Azure CLI
- Kubectl
- Helm Chart
- Helmfile

## Terraform

### Configuration

Assign the RBAC roles "Contributor", "User Access Administrator" to the User account on the Subscription level.

Create a file `terraform.tfvars` and specify the values for the following Terraform variables:

```sh
subscription_id="<subscription_id>"
location="<azure_region>" # e.g. "westeurope"
location_abbreviation="<azure_region_abbreviation>" # e.g. "weu"
environment="<environment_name>" # e.g. "test"
workload_name="<workload_name>"
allowed_public_ip_address_ranges=[<list_of_allowed_ip_address_ranges>] # Public IP Address ranges allowed to access the Azure resources e.g. "1.2.3.4/32"
nginx_internal_load_balancer_ip="<nginx_k8s_svc_ip_address>" # Refer to the step `Update Backend Pool in Azure Application Gateway`
haproxy_internal_load_balancer_ip="<haproxy_k8s_svc_ip_address>" # Refer to the step `Update Backend Pool in Azure Application Gateway`
```

Before proceeding with the next sections, open a terminal and login in Azure with Azure CLI using the User account.

### Terraform Project Initialization

```sh
terraform init -reconfigure
```

### Verify the Updates in the Terraform Code

```sh
terraform plan
```

### Apply the Updates from the Terraform Code

```sh
terraform apply -auto-approve
```

### Format Terraform Code

```sh
find . -not -path "*/.terraform/*" -type f -name '*.tf' -print | uniq | xargs -n1 terraform fmt
```

## Helm

### Create Kubernetes Resources

Execute the following command. Replace <azure_container_registry_login_server> with the FQDN of the Azure Container Registry login server.

```sh
cd helm
helmfile --set image.registry=<azure_container_registry_login_server> apply
```

### Check Kubernetes Resources

```sh
kubectl get all -n ingress-nginx
kubectl get all -n haproxy-ingress
kubectl get all -n application
```

### Update Backend Pool in Azure Application Gateway

After the deployment of the NGINX Ingress Controller in the AKS cluster, run the following command:

```sh
kubectl get svc -n ingress-nginx
```

Copy the IP address of the Kubernetes service "ingress-nginx-controller-internal", update the variable "nginx_internal_load_balancer_ip" in `terraform.tfvars`, and execute `terraform apply`.

After the deployment of the HAProxy Ingress Controller in the AKS cluster, run the following command:

```sh
kubectl get svc -n haproxy-ingress
```

Copy the IP address of the Kubernetes service "haproxy-ingress-kubernetes-ingress", update the variable "haproxy_internal_load_balancer_ip" in `terraform.tfvars`, and execute `terraform apply`.

### Force Pull Latest Image

When using the `latest` tag, AKS caches images on nodes. To force a fresh pull from ACR:

Update the deployment to trigger pod restart.

```sh
kubectl rollout restart deployment/application-react-app -n application
```

### Access Application using NGINX Ingress Controller

The default configuration of the application Helm Chart makes use of the NGINX ingress class.

Add the following in `/etc/hosts`:

```sh
<nginx_agw_public_ip_address> app.local
```

where `<nginx_agw_public_ip_address>` is the Public IP Address of the Azure Application Gateway associated with NGINX Ingress Controller.

Access the application from the URL `http://app.local`.

### Access Application using HAProxy Ingress Controller

The application Helm Chart provides also one ingress resource associated with the HAProxy ingress class.

Update the entry in `/etc/hosts`:

```sh
<haproxy_agw_public_ip_address> app.local
```

where `<haproxy_agw_public_ip_address>` is the Public IP Address of the Azure Application Gateway associated with HAProxy Ingress Controller.

Access the application from the URL `http://app.local`.

## Migration

### Migrate Ingress Resource

Configure the application Helm Chart with the HAProxy ingress resource.

Update the Helm Chart values file `helm/charts/application/values.yaml` with the following:

```yaml
ingress:
  enabled: true
  ingressClassName: haproxy
  annotations:
    kubernetes.io/ingress.class: haproxy
  hosts:
    - host: "app.local"
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

Execute the `helmfile apply` command to apply the changes.

Access the application from the URL `http://app.local`.

The temporary HAProxy ingress resource `helm/charts/application/templates/ingress-haproxy.yaml` can be deleted at this point.

### Decommission NGINX Ingress Controller

The NGINX Ingress Controller can be decommissioned removing the release "ingress-nginx" from `helm/helmfile.yaml` and executing the following command:

```sh
helm uninstall ingress-nginx --namespace ingress-nginx
```

## Cleanup

### Delete Kubernetes Resources

```sh
cd helm
helmfile delete
```

### Delete Azure Resources

```sh
terraform destroy
```
