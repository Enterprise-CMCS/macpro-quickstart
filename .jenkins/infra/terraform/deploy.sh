#!/bin/bash

set -e

# This script is called from one level above its parent dir.  This is a cheap way to set the pwd correctly for the rest of the script.
cd terraform

# Set some environment variables
source ../set.env.sh

#####################################################################################################
# Currently, one of the terraform modules used by this quickstart is private.
# That module is https://github.com/collabralink-technology/terraform-aws-jenkins
# Because of this, we need to tell terraform how to authenticate to github.
# The code below facilitates that authentication.
# terraform-aws-jenkins is expected to be made public soon, at which point this code can be deleted.
echo "machine github.com
login $TF_VAR_git_username_for_jenkins
password $TF_VAR_git_access_token_for_jenkins" > ~/.netrc
#####################################################################################################

# Build a bucket to hold terraform state
cd s3_state
terraform init
terraform apply -auto-approve
cd ..

# Build Jenkins + slave cluster
cd jenkins
terraform init -backend-config="bucket=$TF_VAR_bucket"
terraform apply -auto-approve
cd ..
