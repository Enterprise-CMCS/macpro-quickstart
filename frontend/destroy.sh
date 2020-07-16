#!/bin/bash

docker-compose down --remove-orphans
docker-compose -f docker-compose.dev.yml down --remove-orphans
