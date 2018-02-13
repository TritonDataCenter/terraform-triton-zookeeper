#
# Outputs
#
output "bastion_ip" {
  value = ["${module.bastion.bastion_ip}"]
}

output "zookeeper_ip" {
  value = ["${module.zookeeper.zookeeper_ip}"]
}

output "zookeeper_address" {
  value = ["${module.zookeeper.zookeeper_address}"]
}
