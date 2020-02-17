## packer HCL2 configuration to create a base centos7 image with TFE baked in
## 2020:02:17::ml4
#
source "amazon-ebs" "packer-tfe-centos" {
  ami_description             = "centos7 tfe base image"
  ami_name                    = "centos7tfe"
  associate_public_ip_address = true
  encrypt_boot                = true
  force_delete_snapshot       = true
  force_deregister            = true
  instance_type               = "t2.medium"
  kms_key_id                  = ""
  region                      = "${var.aws_region}"
  shutdown_behavior           = "terminate"
  source_ami                  = "${var.aws_ami}"
  ssh_keypair_name            = "${var.ssh_keypair_name}"
  ssh_private_key_file        = "${var.ssh_private_key_file}"
  ssh_username                = "centos"
}

build {
  sources = [
    # there can be multiple sources per build
    "source.amazon-ebs.packer-tfe-centos"
  ]

  provisioner "shell" {
    inline      = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"]
  }

  provisioner "shell" {
    inline      = ["curl -sSL https://get.replicated.com/docker | sudo bash"]
  }

  # provisioner "shell" {
  #   inline      = ["echo | openssl s_client -servername local -connect $(curl http://169.254.169.254/latest/meta-data/public-ipv4):8800 2>/dev/null | openssl x509 -noout -fingerprint | tee -a /var/tmp/"
  #                 ]
  # }

  provisioner "file" {
    source      = "./tfe/"
    destination = "/var/tmp"
  }

  # provisioner "file" {
  #   destination = "/var/tmp/baseHED.sh"
  #   source      = "baseHED.sh"
  # }

  # provisioner "shell" {
  #   inline      = ["sudo /var/tmp/baseHED.sh ${var.aws_region}"]
  # }

  # provisioner "shell" {
  #   inline      = ["sudo rm -f /var/tmp/baseHED.sh /var/tmp/awslogs.conf"]
  # }
}
