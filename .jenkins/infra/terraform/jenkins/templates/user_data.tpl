#!/bin/bash

# Log userdata execution to /var/log/user-data.log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo BEGIN

# Update packages
yum update -y

# Correct owndership of docker socket to allow it to be mounted and used by the jenkins container
dockergid=`echo $(getent group docker) | cut -d: -f3`
chown 1000:$dockergid /var/run/docker.sock

# Correct owndership of docker socket to allow it to be mounted and used by the jenkins container
dockergid=`echo $(getent group docker) | cut -d: -f3`
chown 1000:$dockergid /var/run/docker.sock

curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# Let the ECS agent know to which cluster this host belongs.
echo ECS_CLUSTER='${ecs_cluster_name}' >> /etc/ecs/ecs.config
docker pull cloudbees/jnlp-slave-with-java-build-tools:2.5.1
echo END
