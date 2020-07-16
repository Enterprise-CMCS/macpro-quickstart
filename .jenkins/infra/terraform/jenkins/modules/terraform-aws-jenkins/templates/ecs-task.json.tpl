[
  {
    "name": "jenkins",
    "image": "${image}",
    "memoryReservation": 1024,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/var/jenkins_home",
        "sourceVolume": "${ebs_volume_name}",
        "readOnly": null
      },
      {
        "containerPath": "/var/run/docker.sock",
        "sourceVolume": "docker_sock"
      },
      {
        "containerPath": "/usr/bin/docker",
        "sourceVolume": "docker_bin"
      }
    ]
  }
]
