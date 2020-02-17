# packer-tfe-centos
Minimally opinionated CentOS 7-based packer config to bake AWS, Azure and GCP machine images with TFE.  This means no CI pipelines, no configuration management tools.
This bake uses marketplace base Centos 7 images for each cloud.  Switch this for an appropriate alternative following the Main Steps in order.

# Prerequisites
1. Packer 1.5.x                   # HCL2 pkr config
1. Local Linux or Unix machine    # Only tested on MacOS Catalina
1. Cloud account(s) set up        # Packer will use the credentials in the local account (e.g. ${HOME}/.aws)

# Main Steps
1. Edit the variables.pkr.hcl and adjust the contents to match your setup for the respective clouds you wish to build for
2. `$ packer build base-TFE-AWS.pkr.hcl`     # For just an AWS AMI

