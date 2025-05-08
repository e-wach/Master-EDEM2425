variable "port" {
    type = string
}

variable "aws-account" {
  type = string
}

variable "cidr_range" {
  default = "10.1.0.0/16"
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

variable "account_id" {
    type = string
}