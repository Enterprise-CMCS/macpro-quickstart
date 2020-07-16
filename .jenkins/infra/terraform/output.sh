#!/bin/bash

set -e

# This script is called from one level above its parent dir.  This is a cheap way to set the pwd correctly for the rest of the script.
cd terraform

# Set some environment variables
source ../set.env.sh

# Terraform output
cd jenkins
terraform init -backend-config="bucket=$TF_VAR_bucket"
terraform output
cd ..
