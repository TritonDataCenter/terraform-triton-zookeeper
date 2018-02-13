#
# Terraform/Providers
#
terraform {
  required_version = ">= 0.11.0"
}

provider "triton" {
  version = ">= 0.4.1"
}

#
# Data sources
#
data "triton_datacenter" "current" {}

data "triton_account" "current" {}

#
# Locals
#
locals {
  machine_name_prefix = "${var.name}-zookeeper"
  zookeeper_address   = "${var.zookeeper_cns_service_name}.svc.${data.triton_account.current.id}.${data.triton_datacenter.current.name}.${var.cns_fqdn_base}"
}

#
# Machines
#
resource "triton_machine" "zookeeper" {
  count = "${var.machine_count}"

  # The machine naming pattern is also used within install_zookeeper.sh to
  # create the zoo.cfg file. Be sure to keep these in sync if this changes.
  name = "${local.machine_name_prefix}-${count.index}"

  package = "${var.package}"
  image   = "${var.image}"

  firewall_enabled = true

  networks = ["${var.networks}"]

  cns {
    services = ["${var.zookeeper_cns_service_name}"]
  }

  metadata {
    zookeeper_version       = "${var.zookeeper_version}"
    zookeeper_name_prefix   = "${local.machine_name_prefix}"
    zookeeper_machine_count = "${var.machine_count}"
    zookeeper_machine_index = "${count.index}"
    cns_fqdn_base           = "${var.cns_fqdn_base}"
  }
}

#
# Firewall Rules
#
resource "triton_firewall_rule" "ssh" {
  rule        = "FROM tag \"role\" = \"${var.bastion_role_tag}\" TO tag \"triton.cns.services\" = \"${var.zookeeper_cns_service_name}\" ALLOW tcp PORT 22"
  enabled     = true
  description = "${var.name} - Allow access from bastion hosts to Zookeeper servers."
}

# see https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.2/bk_reference/content/zookeeper-ports.html
resource "triton_firewall_rule" "zookeeper_client_access" {
  count = "${length(var.client_access)}"

  rule        = "FROM ${var.client_access[count.index]} TO tag \"triton.cns.services\" = \"${var.zookeeper_cns_service_name}\" ALLOW tcp PORT 2181"
  enabled     = true
  description = "${var.name} - Allow access from clients to Zookeeper servers."
}

# see https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.2/bk_reference/content/zookeeper-ports.html
resource "triton_firewall_rule" "zookeeper_to_zookeeper" {
  rule        = "FROM tag \"triton.cns.services\" = \"${var.zookeeper_cns_service_name}\" TO tag \"triton.cns.services\" = \"${var.zookeeper_cns_service_name}\" ALLOW tcp (PORT 2888 AND PORT 3888)"
  enabled     = true
  description = "${var.name} - Allow access from BETWEEN Zookeeper servers."
}
