####################################################################################################
# Creates an ECR image repository to hold the react ui image
####################################################################################################
resource "aws_ecr_repository" "react" {
  name = "react"
  image_scanning_configuration {
    scan_on_push = true
  }
}
####################################################################################################


####################################################################################################
# Creates an ECR image repository to hold the django api image
####################################################################################################
resource "aws_ecr_repository" "django" {
  name = "django"
  image_scanning_configuration {
    scan_on_push = true
  }
}
####################################################################################################

####################################################################################################
# Creates an ECR image repository to hold the postgres_deployer api image
####################################################################################################
resource "aws_ecr_repository" "postgres_deployer" {
  name = "postgres_deployer"
  image_scanning_configuration {
    scan_on_push = true
  }
}
####################################################################################################
