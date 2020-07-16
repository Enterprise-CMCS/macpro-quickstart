#!/bin/bash

set -e

# Build the deployment wrapper docker image
docker build . -t wrapper

# Deploy
docker run --rm --privileged \
  -v $(pwd):/workdir\
  -v /var/run/docker.sock:/var/run/docker.sock\
  -w /workdir wrapper\
  sh terraform/deploy.sh
