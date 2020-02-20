## packer HCL2 configuration to create a base centos7 image which is CIS benchmark-compliant
## 2020:02:14::ml4
#
source "amazon-ebs" "packer-tfe-centos" {
  ami_description             = "centos 7 tfe v4"
  ami_name                    = "base-tfe-v4-airgap"
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
  #
  ## /
  #
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 44
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /var
  #
  launch_block_device_mappings {
    device_name = "/dev/sdf"
    volume_size = 4
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /var/tmp
  #
  launch_block_device_mappings {
    device_name = "/dev/sdg"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /var/log
  #
  launch_block_device_mappings {
    device_name = "/dev/sdh"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /var/log/audit
  #
  launch_block_device_mappings {
    device_name = "/dev/sdi"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /home
  #
  launch_block_device_mappings {
    device_name = "/dev/sdj"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
  }
  #
  ## /var
  #
  ami_block_device_mappings {
    device_name = "/dev/sdf"
    volume_size = 4
    volume_type = "gp2"
    delete_on_termination = true
    # virtual_name = "{{ .SourceAMIName }}-root"
  }
  #
  ## /var/tmp
  #
  ami_block_device_mappings {
    device_name = "/dev/sdg"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
    # virtual_name = "{{ .SourceAMIName }}-var-tmp"
  }
  #
  ## /var/log
  #
  ami_block_device_mappings {
    device_name = "/dev/sdh"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
    # virtual_name = "{{ .SourceAMIName }}-var-log"
  }
  #
  ## /var/log/audit
  #
  ami_block_device_mappings {
    device_name = "/dev/sdi"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
    # virtual_name = "{{ .SourceAMIName }}-var-log-audit"
  }
  #
  ## /home
  #
  ami_block_device_mappings {
    device_name = "/dev/sdj"
    volume_size = 1
    volume_type = "gp2"
    delete_on_termination = true
    # virtual_name = "{{ .SourceAMIName }}-home"
  }
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
    inline      = ["sudo mkdir -p /opt/tfe && sudo chmod 755 /opt/tfe && sudo chown centos:centos /opt/tfe"]
  }

  provisioner "file" {
    source      = "base-centos.sh"
    destination = "/opt/tfe/"
  }

  provisioner "file" {
    source      = "./tfe/"
    destination = "/opt/tfe"
  }

  provisioner "shell" {
    inline      = ["sudo curl -Lo /opt/tfe/replicated.tar.gz https://s3.amazonaws.com/replicated-airgap-work/replicated.tar.gz"]
  }

  provisioner "shell" {
    inline      = ["sudo chmod 750 /opt/tfe/* && sudo chown centos:centos /opt/tfe/*"]
  }

  ## base-centos.sh rearranges file systems (including noexec on /tmp which means adding remote_folder) so watch ordering.
  ## See https://packer.io/docs/provisioners/shell.html#remote_folder
  #
  provisioner "shell" {
    inline      = ["/opt/tfe/base-centos.sh"]
  }

  # provisioner "shell" {
  #   inline      = ["echo | openssl s_client -servername local -connect $(curl http://169.254.169.254/latest/meta-data/public-ipv4):8800 2>/dev/null | openssl x509 -noout -fingerprint | tee -a /var/tmp/"
  #                 ]

  # provisioner "file" {
  #   destination = "/var/tmp/awslogs.conf"
  #   source      = "awslogs.conf"
  # }

  ## AWS
  #
  # provisioner "file" {
  #   source      = "awslogs.conf"
  #   destination = "/tmp/"
  # }
  # provisioner "file" {
  #   source      = "base-AWS.sh"
  #   destination = "/tmp/"
  # }
  # provisioner "shell" {
  #   inline      = ["sudo /tmp/base-AWS.sh"]
  # }

  # provisioner "shell" {
  #   inline      = ["sudo rm -f /tmp/base.sh /tmp/awslogs.conf"]
  # }
}
