## packer HCL2 variables to create a base centos7 image with TFE baked in
## 2020:02:17::ml4
#
variable "ssh_keypair_name" {
  default = "packer.pub"
}
variable "ssh_private_key_file" {
  default = "~/.ssh/packer"
}
