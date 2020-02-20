# packer-tfe-centos
Opinionated, hardened, minimal CentOS 7-based packer config to bake AWS, Azure and GCP machine images with _airgap_ TFE packages.  

* The aim is to just clone/fork to your local machine, add the necessary files (see below) and do a `packer build .` and the AMI should show up in your account.
* The build just puts the files you put in the `tfe` directory in `/opt/tfe` on the machine image.  Your airgapped Terraform Enterprise deployment config can set up from there.
* This bake uses latest marketplace base Centos 7 images for each cloud.  Switch this for an appropriate alternative following the Main Steps in order.
* The build will automatically install the latest replicated.tar.gz airgap tar on the image.
* Tested with packer 1.5.4 on MacOS Catalina.

# Current State
* Builds for AWS only at this point

# Prerequisites
1. Packer 1.5.x                   # HCL2 pkr config
1. Local Linux or Unix machine
1. Cloud account(s) set up        # Packer will use the credentials in the local account (e.g. ${HOME}/.aws) so ensure you have the profile set correctly first
1. Download the TFE airgap pkg    # The new TFE package you need on board
1. Download your licence file     # Your friendly neightbourhood TAM or SE will provide this to you

# Main Steps
1. Edit base-aws-centos-tfe-vars.pkr.hcl and adjust the contents to match your setup for the respective clouds you wish to build for
2. `GITROOT$ PACKER_LOG=1 packer build .`     # For just an AWS AMI, with max output (PACKER_LOG=1)

