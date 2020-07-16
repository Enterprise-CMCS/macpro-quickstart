#!/bin/bash

set -e

# This script is called from one level above its parent dir.  This is a cheap way to set the pwd correctly for the rest of the script.
cd terraform

# Set some environment variables
source ../set.env.sh

current_aws_user=`aws sts get-caller-identity --output text --query 'Arn' | sed 's:.*/::'`
current_aws_access_key_id=$AWS_ACCESS_KEY_ID
current_aws_user=`aws sts get-caller-identity --output text --query 'Arn' | sed 's:.*/::'`
current_aws_account_id=`aws sts get-caller-identity --output text --query 'Account'`

if ! aws iam list-attached-user-policies --user-name $current_aws_user | grep -q arn:aws:iam::aws:policy/AdministratorAccess; then
  echo "The AWS_IAM_USER $current_aws_user does not have a the managed AdministratorAccess policy attached."
  echo "NOT proceeding with destruction, as the current user may be unable to retain account access."
  echo "Attach the AdministratorAccess policy directory to $current_aws_user and try again."
fi

if ! aws iam list-attached-user-policies --user-name $current_aws_user | grep -q arn:aws:iam::aws:policy/IAMUserChangePassword; then
  echo "The AWS_IAM_USER $current_aws_user does not have a the managed IAMUserChangePassword policy attached."
  echo "NOT proceeding with destruction, as the current user may be unable to retain account access."
  echo "Attach the AdministratorAccess policy directory to $current_aws_user and try again."
fi

eval "echo '''
regions:
  - global
  - us-east-1
  - us-east-2
  - us-west-1
  - us-west-2

account-blacklist:
  - \"008087533974\"
  - \"730373213083\"

accounts:
  $current_aws_account_id:
    filters:
      IAMUser:
        - \"$current_aws_user\"
      IAMLoginProfile:
        - \"$current_aws_user\"
      IAMUserPolicyAttachment:
        - \"$current_aws_user -> AdministratorAccess\"
        - \"$current_aws_user -> IAMUserChangePassword\"
      IAMUserAccessKey:
        - \"$current_aws_user -> $current_aws_access_key_id\"
'''" > .nuke-config.yml

# Destroy
echo "***************************************************************
WARNING:  You are about to run AWS Nuke against a real account.
***************************************************************

This is incredibly destructive, and should not be run against any account where you can't afford to lose everything permanently.
Stop and think for a minute.
Does the Nuke Config look correct?"

cat .nuke-config.yml

echo "Sleeping for 30 seconds to encourage a dummy check"

sleep 30

read -p "Do you wish to continue? y/n:  " -n 1 -r
echo
if [[ ! $REPLY =~ ^[yY]$ ]]
then
    exit 1
fi

docker run \
    --rm -it \
    -v $NUKE_CONFIG_FOLDER/.nuke-config.yml:/home/aws-nuke/config.yml \
    quay.io/rebuy/aws-nuke:v2.11.0 \
    --access-key-id $AWS_ACCESS_KEY_ID\
    --secret-access-key $AWS_SECRET_ACCESS_KEY\
    --config /home/aws-nuke/config.yml\
    --no-dry-run

rm -rf jenkins/.terraform
rm -rf s3_state/.terraform
rm -f s3_state/terraform.tf*
