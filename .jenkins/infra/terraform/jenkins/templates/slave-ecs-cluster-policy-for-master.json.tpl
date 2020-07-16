{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecs:RegisterTaskDefinition",
                "ecs:DeregisterTaskDefinition",
                "ecs:ListClusters",
                "ecs:DescribeContainerInstances",
                "ecs:ListTaskDefinitions",
                "ecs:DescribeTaskDefinition"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "ecs:StopTask",
                "ecs:ListContainerInstances"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:ecs:${region}:${account_id}:cluster/${cluster_name}"
        },
        {
            "Action": [
                "ecs:StopTask",
		            "ecs:DescribeTasks"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:ecs:${region}:${account_id}:task/*"
        }
    ]
}
