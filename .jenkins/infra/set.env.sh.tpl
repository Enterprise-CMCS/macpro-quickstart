# Make a copy of this file, in this same directory, and call is set.env.sh
# The set.env.sh is used to inject installation/environment/account specific and/or sensitive information to the infrastrcuture bootstrap process.
# Update the values for all environment variables as appropriate.
# By default, a set.env.sh file in this directory will be ignored by git, allowing you to specify semi-sensitive stuff without commiting it to source control.

# A name for an S3 bucket terraform will create to hold terraform state information.  This need to be globally unique
export TF_VAR_bucket=any-unique-bucket-name-will-do

# The https clone url for this git repository.  This will be used in the Jenkins pipeline(s) configuration
export TF_VAR_git_https_clone_url=https://.......git

# The username Jenkins will use when pulling code from git.
export TF_VAR_git_username_for_jenkins=myJenkinsUser

# An access token for the Jenkins git user.
export TF_VAR_git_access_token_for_jenkins=nepTnotarealtoken4HgGen

# AWS access key id for an iam user with admin permissions
export AWS_ACCESS_KEY_ID=ASDFASDFASDFASDFASD

# AWS secret access key for an iam user with admin permissions
export AWS_SECRET_ACCESS_KEY=jasdv7239v9n23f7vhasdv9723rjnASDF02
