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
You may need add execution permission :
```sh
chmod u+x .terraform/modules/client_vpn/scripts/*
```

### Destroy

```sh
$ terraform destroy
```

## Example

### Using federated authentification (better security) :
- How to setup federated authentification with aws sso here : http://ARTICLE
- You can find the generated Client VPN configuration into your terraform folder.
- AWS VPN Client download link : https://aws.amazon.com/vpn/client-vpn-download/

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
- AWS VPN Client download link : https://aws.amazon.com/vpn/client-vpn-download/

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

### 1. Server certificate generation
Clone and use the latest easy-rsa repo to generate the ca and server certificate.
All the PKI configuration files are saved into your terraform folder.
```sh
#!/usr/bin/env bash

set -x

CWD=$(pwd)

if [ -d "$PKI_FOLDER_NAME" ]; then
    echo "PKI seems to be already configured."
else
    echo "Need to pull project"
    git clone https://github.com/OpenVPN/easy-rsa.git
    mkdir $PKI_FOLDER_NAME
    cp -r easy-rsa/easyrsa3/* $PKI_FOLDER_NAME
    rm -rf easy-rsa
    cd $PKI_FOLDER_NAME
    ./easyrsa init-pki
    echo $CERT_ISSUER | ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    mkdir $KEY_SAVE_FOLDER
    cp pki/ca.crt $KEY_SAVE_FOLDER
    cp pki/issued/server.crt $KEY_SAVE_FOLDER
    cp pki/private/server.key $KEY_SAVE_FOLDER
    cd $KEY_SAVE_FOLDER
fi
```

The server certificate is then created into an ACM ressource.
```sh
resource "aws_acm_certificate" "server_cert" {
  depends_on = [null_resource.server_certificate]

  private_key       = data.local_file.server_private_key.content
  certificate_body  = data.local_file.server_certificate_body.content
  certificate_chain = data.local_file.server_certificate_chain.content

  lifecycle {
    ignore_changes = [options, private_key, certificate_body, certificate_chain]
  }
  tags = {
    Name = var.cert_server_name
  }
}
```

### 2. Client certificate generation
```sh
#!/usr/bin/env bash
set -x 

CWD=$(pwd)
FULL_CLIENT_CERTIFICATE_NAME=$CLIENT_CERT_NAME.$CERT_ISSUER


cd $PKI_FOLDER_NAME
./easyrsa build-client-full $FULL_CLIENT_CERTIFICATE_NAME nopass
cp pki/issued/$FULL_CLIENT_CERTIFICATE_NAME.crt $KEY_SAVE_FOLDER
cp pki/private/$FULL_CLIENT_CERTIFICATE_NAME.key $KEY_SAVE_FOLDER
cd $KEY_SAVE_FOLDER
```

### 3. Create VPN Endpoint Ressource
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

### 4. Authorize the VPN Traffic
```sh
#!/usr/bin/env bash
set -x 

aws ec2 authorize-client-vpn-ingress --profile $AWSCLIPROFILE --client-vpn-endpoint-id $CLIENT_VPN_ID --target-network-cidr $TARGET_CIDR --authorize-all-groups
```

### 5. Generate the vpn configuration
Create the VPN Configuration into your terraform folder.
```bash
#!/usr/bin/env bash
set -x

KEY_SAVE_FOLDER_PATH=$PKI_FOLDER_NAME/$KEY_SAVE_FOLDER
FULL_CLIENT_CERTIFICATE_NAME=$CLIENT_CERT_NAME.$TENANT_NAME
CLIENT_CERTIFICATE=$CLIENT_CERT_NAME.$CERT_ISSUER

aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id $CLIENT_VPN_ID --output text > $FULL_CLIENT_CERTIFICATE_NAME.ovpn

sed -i "s/"$CLIENT_VPN_ID"/"$TENANT_NAME.$CLIENT_VPN_ID"/g" $FULL_CLIENT_CERTIFICATE_NAME.ovpn
echo "<cert>" >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn
cat $KEY_SAVE_FOLDER_PATH/$CLIENT_CERTIFICATE.crt >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn
echo "</cert>" >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn

echo "<key>" >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn
cat $KEY_SAVE_FOLDER_PATH/$CLIENT_CERTIFICATE.key >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn
echo "</key>" >> $FULL_CLIENT_CERTIFICATE_NAME.ovpn
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
vpn_endpoint_subnet_id         = "subnet-12345678"
vpn_endpoint_client_cidr_block = "10.250.0.0/16"
vpn_endpoint_target_cidr_block = "10.0.0.0/8"
vpn_endpoint_vpn_name = "VPN"
vpn_endpoint_client_auth = "federated-authentication"
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
  subnet_id             = var.vpn_endpoint_endpoint_subnet_id
  client_cidr_block     = var.vpn_endpoint_client_cidr_block
  target_cidr_block     = var.vpn_endpoint_target_cidr_block
  vpn_name              = var.vpn_endpoint_vpn_name
  client_client_auth    = var.vpn_endpoint_client_auth
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

variable "vpn_endpoint_dns_servers" {
  type        = list(string)  
  description = "Information about the DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers."
  default     = null
}

variable "vpn_endpoint_vpn_name" {
  type        = string  
  description = "The name of the VPN Client Connection."
  default = "My-VPN"
}

variable "vpn_endpoint_cloudwatch_enabled" {
  type = bool  
  description = "Indicates whether connection logging is enabled."
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

variable "vpn_endpoint_client_auth" {
  type        = string  
  description = "the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication"
  default = "federated-authentication"
}

variable "vpn_endpoint_active_directory_id" {
  type        = string
  description = "The ID of the Active Directory to be used for authentication if type is directory-service-authentication"
  default     = null
}

variable "vpn_endpoint_saml_provider_arn" {
  type        = string  
  description = "The ARN of the IAM SAML identity provider if type is federated-authentication"
  default     = null
}
```
