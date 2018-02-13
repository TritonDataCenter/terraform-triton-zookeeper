# Triton Zookeeper Terraform Module

A Terraform module to create a [Zookeeper](https://zookeeper.apache.org/) cluster.

## Usage

```hcl
data "triton_image" "ubuntu" {
  name        = "ubuntu-16.04"
  type        = "lx-dataset"
  most_recent = true
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_network" "private" {
  name = "My-Fabric-Network"
}

module "bastion" {
  source = "github.com/joyent/terraform-triton-bastion"

  name    = "zookeeper-basic-with-provisioning"
  image   = "${data.triton_image.ubuntu.id}"
  package = "g4-general-4G"

  networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]
}

module "zookeeper" {
  source = "github.com/joyent/terraform-triton-zookeeper"

  name    = "zookeeper-basic-with-provisioning"
  image   = "${data.triton_image.ubuntu.id}"
  package = "g4-general-4G"

  networks = [
    "${data.triton_network.private.id}",
  ]

  provision        = "true"
  private_key_path = "${var.private_key_path}"

  client_access = ["any"]

  bastion_host     = "${element(module.bastion.bastion_ip,0)}"
  bastion_user     = "${module.bastion.bastion_user}"
  bastion_role_tag = "${module.bastion.bastion_role_tag}"
}
```

## Examples
- [basic-with-provisioning](examples/basic-with-provisioning) - Deploys a Zookeeper cluster. Zookeeper servers 
will be _provisioned_ by Terraform.
  - _Note: This method with Terraform provisioning is only recommended for prototyping and light testing._

## Resources created

- [`triton_machine.zookeeper`](https://www.terraform.io/docs/providers/triton/r/triton_machine.html): The Zookeeper machine. 
- [`triton_firewall_rule.ssh`](https://www.terraform.io/docs/providers/triton/r/triton_firewall_rule.html): The firewall
rule(s) allowing SSH access FROM the bastion machine(s) TO the Zookeeper machine.
- [`triton_firewall_rule.zookeeper_client_access`](https://www.terraform.io/docs/providers/triton/r/triton_firewall_rule.html): The 
firewall rule(s) allowing access FROM client machines or addresses TO Zookeeper client ports.
- [`triton_firewall_rule.zookeeper_to_zookeeper`](https://www.terraform.io/docs/providers/triton/r/triton_firewall_rule.html): The 
firewall rule(s) allowing access FROM the Zookeeper servers TO Zookeeper servers.
