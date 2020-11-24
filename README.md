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

## Providers

No provider.

## Usage Example

```hcl
module "client_vpn" {
  source                = "github.com/trackit/terraform-aws-client-vpn?ref=v0.1.0"
  region                = "us-east-1"
  env                   = "production"
  cert_issuer           = "mycompany.internal"
  cert_server_name      = "mycompany"
  aws_tenant_name       = "aws-xyz"
  //key_save_folder
  clients               = ["my_client1", "my_client2"]
  subnet_id             = "subnet-12345678"
  client_cidr_block     = "10.250.0.0/16"
  target_cidr_block     = "10.0.0.0/16"
  vpn_name              = "My VPN Endpoint"
  cloudwatch_log_group  = "my_vpn_log_group"
  cloudwatch_log_stream = "my_vpn_log_stream"
}
```

### Alternative example using variables.tf, vpn.tf and envs.tfvars files
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

variable "vpn_endpoint_vpn_name" {
  type        = string  
  description = "The name of the VPN Client Connection."
  default = "My-VPN"
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
  //key_save_folder     = var.vpn_endpoint_key_save_folder
  subnet_id             = var.vpn_endpoint_subnet_id
  client_cidr_block     = var.vpn_endpoint_client_cidr_block
  target_cidr_block     = var.vpn_endpoint_target_cidr_block
  vpn_name              = var.vpn_endpoint_vpn_name
  cloudwatch_log_group  = var.vpn_endpoint_cloudwatch_log_group
  cloudwatch_log_stream = var.vpn_endpoint_cloudwatch_log_stream
}
```

```hcl
# envs.tfvars
// -- VPN Endpoint
vpn_endpoint_clients = ["user1"]
vpn_endpoint_cert_issuer = "company.internal"
vpn_endpoint_cert_server_name ="company"
vpn_endpoint_aws_tenant_name ="aws-xyz"
//vpn_endpoint_key_save_folder =
vpn_endpoint_subnet_id = "subnet-123456"
vpn_endpoint_client_cidr_block = "10.250.0.0/16"
vpn_endpoint_target_cidr_block = ["10.0.100.0/24","10.0.200.0/24"]
vpn_endpoint_vpn_name = "My-VPN"
vpn_endpoint_cloudwatch_log_group = "my_vpn_log_group"
vpn_endpoint_cloudwatch_log_stream = "my_vpn_log_stream"
```
