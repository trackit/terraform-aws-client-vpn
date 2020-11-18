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

## Usage

```hcl
module "client_vpn" {
  source                = "github.com/trackit/terraform-aws-client-vpn"
  //region                = "us-east-1"
  //env                   = "production"
  cert_issuer           = "mycompany.internal"
  cert_server_name      = "mycompany"
  aws_tenant_name       = "aws"
  //key_save_folder
  clients               = ["my_client1", "my_client2"]
  subnet_id             = "subnet-12345678"
  client_cidr_block     = "10.250.0.0/16"
  target_cidr_block     = "10.0.0.0/16"
  name                  = "My VPN Endpoint"
  cloudwatch_log_group  = "my_vpn_log_group"
  cloudwatch_log_stream = "my_vpn_log_stream"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 2.49 |

## Providers

No provider.
