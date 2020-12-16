# AWS Client VPN Terraform module

Terraform module which creates Client VPN resources on AWS

These type of resources are supported:
- ACM Certificate
- EC2 Client VPN Endpoint
- EC2 Client VPN Network association
- CloudWatch Log Group
- CloudWatch Log Stream

## Terraform versions

Terraform 0.12 and newer.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 2.49 |

## Terraform

This project is using terraform to deploy infrastructure, you can download it here: https://learn.hashicorp.com/tutorials/terraform/install-cli

### Deploy

```sh
$ cd ./tf
$ terraform init
$ terraform plan
$ terraform apply
```

### Destroy

```sh
$ terraform destroy
```


## Example usage for your terraform file

### Using federated authentification (better security) :
=> How to setup federated authentification with aws sso here : http://ARTICLE

```hcl
module "client_vpn" {
  source                = "github.com/trackit/terraform-aws-client-vpn?ref=v0.2.0"
  region                = "us-east-1"
  env                   = "production"
  cert_issuer           = "mycompany.internal"
  cert_server_name      = "mycompany"
  aws_tenant_name       = "aws"
  clients               = ["client"]
  subnet_id             = "subnet-12345678"
  client_cidr_block     = "10.250.0.0/16"
  target_cidr_block     = "10.0.0.0/16"
  vpn_name              = "My VPN Endpoint"
  client_authentication_options = "federated-authentication"
  saml_provider_arn = "arn:12345678"
}
```

### Certificate authentification only
```hcl
module "client_vpn" {
  source                = "github.com/trackit/terraform-aws-client-vpn?ref=v0.2.0"
  region                = "us-east-1"
  env                   = "production"
  cert_issuer           = "mycompany.internal"
  cert_server_name      = "mycompany"
  aws_tenant_name       = "aws"
  clients               = ["client"]
  subnet_id             = "subnet-12345678"
  client_cidr_block     = "10.250.0.0/16"
  target_cidr_block     = "10.0.0.0/16"
  vpn_name              = "My VPN Endpoint"
  client_authentication_options = "certificate-authentication"
}
```

## Alternative example using tfvars file

You may want use this project with `terraform workspace` and a `envs` directory to deploy different configuration files (prod.tfvars, dev.tfvars...)

```hcl
# envs.tfvars
// -- VPN Endpoint
vpn_endpoint_clients = ["client"]
vpn_endpoint_cert_issuer = "company.internal"
vpn_endpoint_cert_server_name ="company"
vpn_endpoint_aws_tenant_name ="aws"
vpn_endpoint_client_cidr_block = "10.250.0.0/16"
vpn_endpoint_target_cidr_block = "10.0.0.0/8"
vpn_endpoint_vpn_name = "VPN"
vpn_endpoint_client_authentication_options = "federated-authentication"
vpn_endpoint_saml_provider_arn = "arn:123456"
```

```hcl
# vpn.tf
module "client_vpn" {
  source                = "github.com/trackit/terraform-aws-client-vpn"
  region                = var.region
  env                   = var.env
  clients               = var.vpn_endpoint_clients
  cert_issuer           = var.vpn_endpoint_cert_issuer
  cert_server_name      = var.vpn_endpoint_cert_server_name
  aws_tenant_name       = var.vpn_endpoint_aws_tenant_name
  subnet_id             = var.vpn_vpn_endpoint_subnet_id
  client_cidr_block     = var.vpn_endpoint_client_cidr_block
  target_cidr_block     = var.vpn_endpoint_target_cidr_block
  vpn_name              = var.vpn_endpoint_vpn_name
  client_authentication_options = var.vpn_endpoint_client_authentication_options
  saml_provider_arn     = var.vpn_endpoint_saml_provider_arn
}
```

```hcl
# variables.tf
/*
// VPN Endpoint variables
*/

variable "vpn_endpoint_clients" {
  type        = list(string)
  description = "A list of client certificate name"
  default = ["client"]
}

variable "vpn_endpoint_cert_issuer" {
  type        = string
  description = "Common Name for CA Certificate"
  default = "CA"
}

variable "vpn_endpoint_cert_server_name" {
  type        = string  
  description = "Name for the Server Certificate"
  default = "Server"
}

variable "vpn_endpoint_aws_tenant_name" {
  type        = string  
  description = "Name for the AWS Tenant"
  default = "AWS"
}

variable "vpn_endpoint_key_save_folder" {
  type        = string  
  description = "Where to store keys (relative to pki folder)"
  default     = "clientvpn_keys"
}

variable "vpn_endpoint_subnet_id" {
  type        = string
  description = "The subnet ID to which we need to associate the VPN Client Connection."
}

variable "vpn_endpoint_client_cidr_block" {
  type        = string  
  description = "VPN CIDR block, must not overlap with VPC CIDR. Client cidr block must be at least a /22 range."
}

variable "vpn_endpoint_target_cidr_block" {
  type        = string  
  description = "The CIDR block to wich the client will have access to. Might be VPC CIDR's block for example."
}

variable "dns_servers" {
  description = "Information about the DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers."
  type        = list(string)
  default     = null
}

variable "vpn_endpoint_vpn_name" {
  type        = string  
  description = "The name of the VPN Client Connection."
  default = "My-VPN"
}

variable "cloudwatch_enabled" {
  description = "Indicates whether connection logging is enabled."
  type = bool
  default = true
}

variable "vpn_endpoint_cloudwatch_log_group" {
  type        = string  
  description = "The name of the cloudwatch log group."
  default = "vpn_endpoint_cloudwatch_log_group"
}

variable "vpn_endpoint_cloudwatch_log_stream" {
  type        = string  
  description = "The name of the cloudwatch log stream."
  default = "vpn_endpoint_cloudwatch_log_stream"
}

variable "vpn_aws_cli_profile_name" {
  type        = string  
  description = "the name of the aws cli profile used in scripts"
  default = "default"
}

variable "vpn_client_authentication_options" {
  type        = string  
  description = "the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication"
  default = "federated-authentication"
}

variable "active_directory_id" {
  description = "The ID of the Active Directory to be used for authentication if type is directory-service-authentication"
  type        = string
  default     = null
}

variable "saml_provider_arn" {
  description = "The ARN of the IAM SAML identity provider if type is federated-authentication"
  type        = string
  default     = null
}
```
