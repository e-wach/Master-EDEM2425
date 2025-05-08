# SNS topic and sub
resource "aws_sns_topic" "sns-topic" {
  name = "website-sns-topic"
}

resource "aws_sns_topic_subscription" "sqs-sub" {
  topic_arn = aws_sns_topic.sns-topic.arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.sqs-queue.arn
}

# SQS queue
resource "aws_sqs_queue" "sqs-queue" {
    name = "website-sqs-queue"
}

resource "aws_sqs_queue_policy" "sqs-policy" {
  queue_url = aws_sqs_queue.sqs-queue.id
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = "*"
          Action = "SQS:SendMessage"
          Resource = aws_sqs_queue.sqs-queue.arn
          Condition = {
            StringEquals = {
              "aws:SourceArn" = aws_sns_topic.sns-topic.arn
            }}
        }
      ]
    })
}

# IAM Roles for Lambda
resource "aws_iam_role" "lambda-role" {
  name = "LambdaSQStoRDSRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc-policy" {
  name = "LambdaVPCPolicy"
  role = aws_iam_role.lambda-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecr-policy" {
  name = "LambdaECRPolicy"
  role = aws_iam_role.lambda-role.id
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

resource "aws_iam_role_policy" "sqs-policy" {
  name = "RDSLambdaPolicy"
  role = aws_iam_role.lambda-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch-policy" {
  name = "LogsPolicy"
  role = aws_iam_role.lambda-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:eu-central-1:${var.aws-account}:log-group:/aws/lambda/*"
      },
    ]
  })
}

# Lambda function SQS to RDS (ECR image)
resource "aws_ecr_repository" "ecr-lambda-repo" {
  name = "lambda-repo"
  force_delete = true
}

resource "null_resource" "image-push-lambda" {
  provisioner "local-exec" {
    command = <<EOT
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${var.aws-account} && set DOCKER_BUILDKIT=0&& docker build -t lambda-repo -f ../lambda/Dockerfile ../lambda && docker tag lambda-repo:latest ${aws_ecr_repository.ecr-lambda-repo.repository_url}:latest && docker push ${aws_ecr_repository.ecr-lambda-repo.repository_url}:latest
    EOT
  }
  # triggers = {
  #   always_run = timestamp()
  # }
  depends_on = [aws_ecr_repository.ecr-lambda-repo]
}

resource "aws_lambda_function" "lambda-function" {
  function_name = "SNStoRDS"
  role = aws_iam_role.lambda-role.arn
  package_type = "Image"
  image_uri = "${aws_ecr_repository.ecr-lambda-repo.repository_url}:latest"
  environment {
    variables = {
        "RDS_HOST" = var.db_host
        "RDS_USER" = var.rds_root_user
        "RDS_PASS" = var.rds_root_pass
        "RDS_DB" = var.rds_db
        "SQS_QUEUE_URL" = aws_sqs_queue.sqs-queue.url
        }
  }
  vpc_config {
    subnet_ids = [var.private-subnet-1, var.private-subnet-2]
    security_group_ids = [var.security_group_id]
  }
  depends_on = [ null_resource.image-push-lambda ]
}

resource "aws_lambda_event_source_mapping" "sqs-trigger" {
  event_source_arn = aws_sqs_queue.sqs-queue.arn
  function_name    = aws_lambda_function.lambda-function.arn
}