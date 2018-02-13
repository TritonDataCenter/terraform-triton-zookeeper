#
# Variables
#
variable "name" {
  description = "The name of the environment."
  type        = "string"
}

variable "image" {
  description = "The image to deploy as the Zookeeper machine(s)."
  type        = "string"
}

variable "package" {
  description = "The package to deploy as the Zookeeper machine(s)."
  type        = "string"
}

variable "networks" {
  description = "The networks to deploy the Zookeeper machine(s) within."
  type        = "list"
}

variable "private_key_path" {
  description = "The path to the private key to use for provisioning machines."
  type        = "string"
}

variable "user" {
  description = "The user to use for provisioning machines."
  type        = "string"
  default     = "root"
}

variable "provision" {
  description = "Boolean 'switch' to indicate if Terraform should do the machine provisioning to install and configure Zookeeper."
  type        = "string"
}

variable "zookeeper_version" {
  default     = "3.4.10"
  description = "The version of Zookeeper to install. See https://zookeeper.apache.org/releases.html."
  type        = "string"
}

variable "machine_count" {
  default     = "3"
  description = "The number of Zookeeper servers to provision."
  type        = "string"
}

variable "zookeeper_cns_service_name" {
  description = "The Zookeeper CNS service name. Note: this is the service name only, not the full CNS record."
  type        = "string"
  default     = "zookeeper"
}

variable "client_access" {
  description = <<EOF
'From' targets to allow client access to Zookeeper' client port - i.e. access from other VMs or public internet.
See https://docs.joyent.com/public-cloud/network/firewall/cloud-firewall-rules-reference#target
for target syntax.
EOF

  type    = "list"
  default = ["any"]
}

variable "cns_fqdn_base" {
  description = "The fully qualified domain name base for the CNS address - e.g. 'cns.joyent.com' for Joyent Public Cloud."
  type        = "string"
  default     = "cns.joyent.com"
}

variable "bastion_host" {
  description = "The Bastion host to use for provisioning."
  type        = "string"
}

variable "bastion_user" {
  description = "The Bastion user to use for provisioning."
  type        = "string"
}

variable "bastion_role_tag" {
  description = "The 'role' tag for the Zookeeper machine(s) to allow access FROM the Bastion machine(s)."
  type        = "string"
}
