{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Action": "*",
          "Resource": "*"
        },
        {
           "Action": [
               "ecs:RunTask"
           ],
           "Effect": "Allow",
           "Resource": "arn:aws:ecs:${region}:${account_id}:task-definition/${task_definition_name}:*"
        }
    ]
}
