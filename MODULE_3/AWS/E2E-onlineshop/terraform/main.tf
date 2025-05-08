terraform {
    backend "s3" {
        bucket = "tf-terraform-app"
        key    = "terraform/terraform.tfstate"
        region = "eu-central-1"
    }
}

module "apprunner" {
  source = "./modules/apprunner"
  providers = {
      aws= aws.master_region
    }
  aws-account = var.aws-account
  port = var.port
  rds_db = var.rds_db
  rds_root_user = var.rds_root_user
  rds_root_pass = var.rds_root_pass
  db_host = module.RDS.db_host
  sns_topic_arn = module.msg-lambda.sns_topic_arn
  vpc_connector_arn = module.RDS.vpc_connector_arn
  depends_on = [ module.msg-lambda ]
}

module "RDS" {
  source = "./modules/RDS"
  providers = {
      aws= aws.master_region
    }
  cidr_range = var.cidr_range
  rds_db = var.rds_db
  rds_root_pass = var.rds_root_pass
  rds_root_user = var.rds_root_user
  private-subnet-1 = module.RDS.private-subnet-1
  private-subnet-2 = module.RDS.private-subnet-2
  security_group_id = module.RDS.security_group_id
  aws-account = var.aws-account
  account_id = var.account_id
}

module "msg-lambda" {
  source = "./modules/msg-lambda"
  providers = {
      aws= aws.master_region
    }
  aws-account = var.aws-account
  rds_db = var.rds_db
  rds_root_user = var.rds_root_user
  rds_root_pass = var.rds_root_pass
  db_host = module.RDS.db_host
  private-subnet-1 = module.RDS.private-subnet-1
  private-subnet-2 = module.RDS.private-subnet-2
  security_group_id = module.RDS.security_group_id
}

