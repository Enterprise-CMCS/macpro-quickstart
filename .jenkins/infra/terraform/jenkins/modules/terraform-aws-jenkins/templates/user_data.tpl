#!/bin/bash

# Log userdata execution to /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo BEGIN

# Update packages
yum update -y

# Correct owndership of docker socket to allow it to be mounted and used by the jenkins container
dockergid=`echo $(getent group docker) | cut -d: -f3`
chown 1000:$dockergid /var/run/docker.sock

# Install rexray plugin to help with persistent EBS storage orchestration
until docker plugin install rexray/ebs REXRAY_PREEMPT=true EBS_REGION=${ebs_region} --grant-all-permissions
do
  echo "docker plugin install failed.  Retrying in 5s" && sleep 5
done

# Let the ECS agent know to which cluster this host belongs.
echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config

echo END
