## packer HCL2 variables to create a base centos7 image with TFE baked in
## 2020:02:17::ml4
#
variable "aws_region" {
  default = "eu-west-2"
}
variable "aws_ami" {
  default = "ami-0eab3a90fc693af19"
}
