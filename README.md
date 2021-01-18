# AWS Client VPN Terraform module

Terraform module which creates Client VPN Endpoint resources on AWS.

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
| bash |  |

## Upcoming features
- Client certificate revocation list
- Self Service VPN Portal


## Terraform

This project is using terraform to deploy infrastructure, you can download it here: https://learn.hashicorp.com/tutorials/terraform/install-cli

### Deploy

```sh
$ cd ./tf
$ terraform init
$ terraform plan
$ terraform apply
```
You may need to add execution permission :
```sh
chmod u+x .terraform/modules/client_vpn/scripts/*
```

### Destroy

```sh
$ terraform destroy
```

## Example

### Using federated authentification (best security) :
- AWS VPN Client download link : https://aws.amazon.com/vpn/client-vpn-download/
- You can find the generated Client VPN configuration into your terraform folder.
- Each user have a login/password to authenticate.

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
  client_auth           = "federated-authentication"
  saml_provider_arn     = "arn:12345678"
}
```

### Server certificate authentification only (less secure)
- You can find the generated Client VPN configuration into your terraform folder.
- Be carefull no user/password needed. Only the configuration file so do not lost it.

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
  client_auth           = "certificate-authentication"
}
```

### Variable list

| Name | Description | Type | Default |
|------|-------------|------|---------|
| region | Region to work on. | string | |
| env | The environment (e.g. prod, dev, stage) | string | "prod" |
| clients | A list of client certificate name | list(string) | ["client"] |
| cert_issuer | Common Name for CA Certificate | list(string) | "CA" |
| cert_server_name | Name for the Server Certificate | string | "Server" |
| aws_tenant_name | Name for the AWS Tenant | string | "AWS" |
| key_save_folder | Where to store keys (relative to pki folder) | string | "clientvpn_keys" |
| subnet_id | The subnet ID to which we need to associate the VPN Client Connection. | string | |
| target_cidr_block | The CIDR block to wich the client will have access to. Might be VPC CIDR's block for example. | string | |
| dns_servers | Information about the DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers. | list(string) | null |
| vpn_name | The name of the VPN Client Connection. | string | "VPN" |
| cloudwatch_enabled | Indicates whether connection logging is enabled. | bool | true |
| cloudwatch_log_group | The name of the cloudwatch log group. | string | vpn_endpoint_cloudwatch_log_group |
| cloudwatch_log_stream | The name of the cloudwatch log stream. | string | vpn_endpoint_cloudwatch_log_stream |
| aws_cli_profile_name | The name of the aws cli profile used in scripts | string | default |
| client_auth | the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication | string | certificate-authentication |
| active_directory_id | The ID of the Active Directory to be used for authentication if type is directory-service-authentication | string | null |
| root_certificate_chain_arn | The ARN of the client certificate. The certificate must be signed by a certificate authority (CA) and it must be provisioned in AWS Certificate Manager (ACM). Only necessary when type is set to certificate-authentication. | string | null |
| saml_provider_arn | The ARN of the IAM SAML identity provider if type is federated-authentication | string | null |

### Output
| Name | Description |
|------|-------------|
| kms_sops_arn | |
| decrypt_command | Output of the decrypt script |
| encrypt_command | Output of the encrypt script |
| server_certificate_arn | The ARN of the generated Server Certificate |
| env | Environment variable |
| pki_folder_name | Generated certificate folder |
| client_vpn_endpoint_id | The ID of the Client VPN endpoint. |
| client_vpn_endpoint_arn | The ARN of the Client VPN endpoint. |
| client_vpn_endpoint_dns_name | The DNS name to be used by clients when establishing their VPN session. |
| client_vpn_endpoint_status | The current state of the Client VPN endpoint. |

## How does it work ?

### 1. Server certificate generation (scripts/prepare_easyrsa.sh)
1. Clone the latest [easy-rsa](https://github.com/OpenVPN/easy-rsa.git) repo.
2. Generate the CA and Server certificates and keys.
3. Copy the files to the defined KEY_SAVE_FOLDER.
4. the Server certificate is uploaded into AWS ACM.

### 2. Client certificate generation (scripts/create_client.sh)
1. Using the previous created PKI, generate a client certificate / key pair.
2. Then move it to the KEY_SAVE_FOLDER.

### 3. Create a VPN Endpoint Ressource

```hcl
resource "aws_ec2_client_vpn_endpoint" "client_vpn" {
  depends_on             = [aws_acm_certificate.server_cert]
  description            = var.vpn_name
  server_certificate_arn = aws_acm_certificate.server_cert.arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = true
  dns_servers            = var.dns_servers

  lifecycle {
    ignore_changes = [server_certificate_arn, authentication_options]
  }

  authentication_options {
    type                        = var.client_auth
    active_directory_id         = var.active_directory_id
    root_certificate_chain_arn  = var.root_certificate_chain_arn
    saml_provider_arn           = var.saml_provider_arn
  }

  connection_log_options {
    enabled               = var.cloudwatch_enabled
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
  }

  provisioner "local-exec" {
    environment = merge(local.provisioner_base_env, {
      "CLIENT_VPN_ID" = self.id
    })
    command = "${path.module}/scripts/authorize_client.sh"
  }

  tags = {
    Name = var.vpn_name
  }
}
```

### 4. Authorize the VPN Traffic (scripts/authorize_client.sh)
1. With aws-cli allow traffic to TARGET_CIDR from CLIENT_VPN_ID

### 5. Generate the vpn configuration (scripts/export_client_vpn_config.sh)
1. With aws-cli export the ovpn configuration file.
2. Add the client certificate to end of it.
3. Add the opvn configuration to AWS VPN Client.
4. Start the VPN.