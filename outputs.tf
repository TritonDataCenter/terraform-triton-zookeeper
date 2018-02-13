#
# Outputs
#
output "zookeeper_ip" {
  value = ["${triton_machine.zookeeper.*.primaryip}"]
}

output "zookeeper_cns_service_name" {
  value = "${var.zookeeper_cns_service_name}"
}

output "zookeeper_address" {
  value = "${local.zookeeper_address}"
}
