variable "region" {
  description = "Selected AWS region"
}

variable "env" {
  description = "The environment (e.g. prod, dev, stage)"
}

variable "clients" {
  description = "A list of client certificate name"
}

variable "cert_issuer" {
  description = "Common Name for CA Certificate"
  default = "CA"
}

variable "cert_server_name" {
  description = "Name for the Server Certificate"
  default = "Server"
}

variable "aws_tenant_name" {
  description = "Name for the AWS Tenant"
  default = "AWS"
}

variable "key_save_folder" {
  description = "Where to store keys (relative to pki folder)"
  default     = "clientvpn_keys"
}

variable "subnet_id" {
  description = "The subnet ID to which we need to associate the VPN Client Connection."
  type        = string
}

variable "client_cidr_block" {
  description = "VPN CIDR block, must not overlap with VPC CIDR. Client cidr block must be at least a /22 range."
  type        = string
}

variable "target_cidr_block" {
  description = "The CIDR block to wich the client will have access to. Might be VPC CIDR's block for example."
}

variable "dns_servers" {
  description = "Information about the DNS servers to be used for DNS resolution. A Client VPN endpoint can have up to two DNS servers."
  type        = list(string)
  default     = null
}

variable "vpn_name" {
  description = "The name of the VPN Client Connection."
  type        = string
  default     = "My-VPN"
}

variable "cloudwatch_log_group" {
  description = "The name of the cloudwatch log group."
  type        = string
}

variable "cloudwatch_log_stream" {
  description = "The name of the cloudwatch log stream."
  type        = string
}

variable "aws_cli_profile_name" {
  description = "the name of the aws cli profile used in scripts"
  type        = string
  default     = "default"
}

variable "client_authentication_options" {
  description = "the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication"
  type        = string
  default     = "certificate-authentication"
}

variable "active_directory_id" {
  description = "The ID of the Active Directory to be used for authentication if type is directory-service-authentication"
  type        = string
  default     = null
}

variable "root_certificate_chain_arn" {
  description = "the type of client authentication to be used : certificate-authentication / directory-service-authentication / federated-authentication"
  type        = string
  default = null
}

variable "saml_provider_arn" {
  description = "The ARN of the IAM SAML identity provider if type is federated-authentication"
  type        = string
  default     = null
}