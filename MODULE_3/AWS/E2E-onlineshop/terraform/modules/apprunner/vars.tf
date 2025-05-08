variable "aws-account" {
  type = string
}

variable "port" {
    type = string
}

variable "db_host" {
    type = string
}

variable "rds_root_user" {
    type = string
}

variable "rds_root_pass" {
    type = string
}

variable "rds_db" {
    type = string
}

variable "vpc_connector_arn" {
    type = string
}

variable "sns_topic_arn" {
    type = string
}
