resource "null_resource" "zookeeper_install" {
  count = "${var.provision == "true" ? var.machine_count : 0}"

  triggers {
    machine_ids = "${triton_machine.zookeeper.*.id[count.index]}"
  }

  connection {
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.private_key_path)}"

    host        = "${triton_machine.zookeeper.*.primaryip[count.index]}"
    user        = "${var.user}"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/zookeeper_installer/",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/packer/scripts/install_zookeeper.sh"
    destination = "/tmp/zookeeper_installer/install_zookeeper.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/zookeeper_installer/install_zookeeper.sh",
      "sudo /tmp/zookeeper_installer/install_zookeeper.sh",
    ]
  }

  # clean up
  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/zookeeper_installer/",
    ]
  }
}
