# VPC & Security resources
resource "aws_vpc" "main-vpc" {
    cidr_block = var.cidr_range
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block = "10.1.1.0/24"
  vpc_id = aws_vpc.main-vpc.id
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet"
  }
}

resource "aws_subnet" "private-subnet-1" {
  cidr_block = "10.1.2.0/24"
  vpc_id = aws_vpc.main-vpc.id
  availability_zone = "eu-central-1b"
  tags = {
    Name = "Private subnet"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "eu-central-1c"

  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_apprunner_vpc_connector" "connector_AR" {
  vpc_connector_name = "arconnector"
  subnets            = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
  security_groups    = [aws_security_group.vpc-group.id]
}

resource "aws_vpc_endpoint" "sns-endpoint" {
  vpc_id = aws_vpc.main-vpc.id
  service_name = "com.amazonaws.eu-central-1.sns"
  vpc_endpoint_type = "Interface"
  auto_accept = true
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
  security_group_ids = [aws_security_group.vpc-group.id]
  private_dns_enabled = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main-vpc.id
    tags = {
      Name = "Main IGW"
    }
}

resource "aws_route_table" "public-table" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public-table.id
}

resource "aws_route_table_association" "private_rt_assoc_1" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_db_subnet_group" "subnet-group" {
    name = "vpc-subnet-group"
    subnet_ids = [
      aws_subnet.private-subnet-1.id, 
      aws_subnet.private-subnet-2.id
    ]
}

resource "aws_security_group" "vpc-group" {
  name        = "vpc-security-group"
  vpc_id      = aws_vpc.main-vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "Main security group"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw]
}

############ RDS INSTANCE ############
resource "aws_db_instance" "rds-db-website" {
  allocated_storage    = 10
  db_name              = var.rds_db
  engine               = "mysql"
  engine_version       = "8.0"
  multi_az = false
  instance_class       = "db.t3.micro"
  username             = var.rds_root_user
  password             = var.rds_root_pass
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.vpc-group.id]
  db_subnet_group_name = aws_db_subnet_group.subnet-group.name

  tags = {
    Name = "RDS MySQL Private"
  }
}

########### RDS SNAPSHOT TO S3 ###########

# S3 Bucket for snapshot data
resource "aws_s3_bucket" "rds-bucket" {
  bucket = "rds-websitedb-snapshot-bucket"
  force_destroy = true
}

# IAM Role for RDS to S3
resource "aws_iam_role" "snapshot-role" {
  name = "RDSsnapshotToS3"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3-policy" {
  name = "S3Policy"
  role = aws_iam_role.snapshot-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "s3:PutObject*",
            "s3:ListBucket",
            "s3:GetObject*",
            "s3:DeleteObject*",
            "s3:GetBucketLocation"
            ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# KMS key for encryption
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds-kms-key" {
  description = "New KMS key for RDS encryption to S3"
  deletion_window_in_days = 7
  enable_key_rotation = true
    tags = {
    Name = "KMSKeyWebsite"
  }
  }

resource "aws_kms_key_policy" "rds-kms-key-policy" {
  key_id = aws_kms_key.rds-kms-key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
      {
        "Sid": "Allow access for Key Administrators",
        Effect = "Allow"
        Principal = {
          "AWS": "*"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# Lambda docker image to ECR
resource "aws_ecr_repository" "ecr-lambda-s3-repo" {
  name = "lambda-snapshot-repo"
  force_delete = true
}

resource "null_resource" "image-push-lambda-snapshot" {
  provisioner "local-exec" {
    command = <<EOT
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${var.aws-account} && set DOCKER_BUILDKIT=0&& docker build -t lambda-snapshot-repo -f ../lambda-bucket/Dockerfile ../lambda-bucket && docker tag lambda-snapshot-repo:latest ${aws_ecr_repository.ecr-lambda-s3-repo.repository_url}:latest && docker push ${aws_ecr_repository.ecr-lambda-s3-repo.repository_url}:latest
    EOT
  }
  # triggers = {
  #   always_run = timestamp()
  # }
}

# IAM Role for Lambda (RDS, S3 and KMS)
resource "aws_iam_role" "lambda-snapshot-role" {
  name = "LambdaSnapshotRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda-snapshot-policy" {
  name = "LambdaSnapshotPolicy"
  role = aws_iam_role.lambda-snapshot-role.id
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
      {
        Action = [
          "rds:StartExportTask",
          "rds:CreateDBSnapshot",
          "rds:DescribeDBSnapshots"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject*",
          "s3:GetBucketLocation"]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = "kms:Decrypt"
        Effect = "Allow"
        Resource = "${aws_kms_key.rds-kms-key.arn}"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
      Action = "iam:PassRole"
      Effect = "Allow"
      Resource = "${aws_iam_role.snapshot-role.arn}"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Lambda function to create RDS snapshot and export to S3
resource "aws_lambda_function" "lambda-snapshot" {
  function_name = "RDStoS3"
  role = aws_iam_role.lambda-snapshot-role.arn
  package_type = "Image"
  image_uri = "${aws_ecr_repository.ecr-lambda-s3-repo.repository_url}:latest"
  timeout = 300
  environment {
    variables = {
      "DB_ID" = aws_db_instance.rds-db-website.identifier
      "BUCKET_NAME" = aws_s3_bucket.rds-bucket.bucket
      "KMS_KEY_ID" = aws_kms_key.rds-kms-key.key_id
      "IAM_ROLE_ARN" = aws_iam_role.snapshot-role.arn
      "ACCOUNT_ID" = data.aws_caller_identity.current.account_id
      }
  }
  vpc_config {
    subnet_ids = [var.private-subnet-1, var.private-subnet-2]
    security_group_ids = [var.security_group_id]
  }
  depends_on = [ null_resource.image-push-lambda-snapshot ]
}

# Lambda trigger every 12 hours
resource "aws_cloudwatch_event_rule" "snapshot_schedule" {
  name                = "daily-snapshot-rule"
  schedule_expression = "rate(12 hours)"
}

resource "aws_cloudwatch_event_target" "snapshot_target" {
  rule      = aws_cloudwatch_event_rule.snapshot_schedule.name
  target_id = "lambda-target"
  arn       = aws_lambda_function.lambda-snapshot.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-snapshot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.snapshot_schedule.arn
}