# ECR Image (Docker) to create AppRunner service 
resource "aws_ecr_repository" "ecr-repo" {
  name = "website-repo"
  force_delete = true
}

resource "null_resource" "image-push" {
  provisioner "local-exec" {
    command = <<EOT
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${var.aws-account} && docker build -t website-repo -f ../api/Dockerfile ../api && docker tag website-repo:latest ${aws_ecr_repository.ecr-repo.repository_url}:latest && docker push ${aws_ecr_repository.ecr-repo.repository_url}:latest
    EOT
  }
  # triggers = {
  #   always_run = timestamp()
  # }
}

# IAM Roles for AppRunner
resource "aws_iam_role" "apprunner-access-role" {
  name = "AppRunnerToECRRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecr-policy" {
  name = "AppRunnerECRPolicy"
  role = aws_iam_role.apprunner-access-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "sns-policy" {
  name = "AppRunnerSNSPolicy"
  role = aws_iam_role.apprunner-access-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [ "sns:Publish" ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "apprunner-instance-role" {
  name = "AppRunnerToSNSRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "sns-policy-instance" {
  name = "AppRunnerSNSInstancePolicy"
  role = aws_iam_role.apprunner-instance-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [ "sns:Publish" ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# App Runner service
resource "aws_apprunner_service" "app-web" {
  service_name = "app-web"
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-access-role.arn
    }
    image_repository {
      image_configuration {
        port = var.port
        runtime_environment_variables = {
          "RDS_HOST" = var.db_host
          "RDS_USER" = var.rds_root_user
          "RDS_PASS" = var.rds_root_pass
          "RDS_DB" = var.rds_db
          "SNS_TOPIC_ARN" = var.sns_topic_arn }
      }
      image_identifier      = "${aws_ecr_repository.ecr-repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }
  network_configuration {
    egress_configuration {
      egress_type = "VPC"
      vpc_connector_arn = var.vpc_connector_arn
    }
  }
  instance_configuration {
    instance_role_arn = aws_iam_role.apprunner-instance-role.arn
  }
}


        
      