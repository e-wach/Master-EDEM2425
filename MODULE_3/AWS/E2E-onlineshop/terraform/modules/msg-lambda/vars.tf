variable "aws-account" {
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

variable "private-subnet-1" {
  type = string
}

variable "private-subnet-2" {
  type = string
}

variable "security_group_id" {
  type = string
}
