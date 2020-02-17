# packer-tfe-centos
Minimally opinionated CentOS 7-based packer config to bake AWS, Azure and GCP machine images with TFE.  This means no CI pipelines, no configuration management tools.
This bake uses marketplace base Centos 7 images for each cloud.  Switch this for an appropriate alternative following the Main Steps in order.
Tested with packer 1.5.4 on MacOS Catalina.

# Prerequisites
1. Packer 1.5.x                   # HCL2 pkr config
1. Local Linux or Unix machine    
1. Cloud account(s) set up        # Packer will use the credentials in the local account (e.g. ${HOME}/.aws)
1. Download replicated.tar.gz     # Ensure the version of replicated you want to use is compatible with the TFE airgap package
                                  # tar -zxOf replicated.tar.gz install.sh | grep REPLICATED_VERSION | head -1 | cut -d'"' -f2
                                  # https://www.terraform.io/docs/enterprise/before-installing/index.html#software-requirements-individual-deployment-
1. Download the TFE airgap pkg    # The new TFE package you need on board
1. Download your licence file     # Your friendly neightbourhood TAM or SE will provide this to you

# Main Steps
1. Edit the variables.pkr.hcl and adjust the contents to match your setup for the respective clouds you wish to build for
2. `$ packer build base-TFE-AWS.pkr.hcl`     # For just an AWS AMI

