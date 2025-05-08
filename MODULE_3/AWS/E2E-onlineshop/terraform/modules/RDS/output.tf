output "db_host" {
    value = aws_db_instance.rds-db-website.endpoint
}

output "vpc_connector_arn" {
  description = "The ARN of the VPC connector"
  value = aws_apprunner_vpc_connector.connector_AR.arn
}

output "security_group_id" {
  description = "Security group ID"
  value = aws_security_group.vpc-group.id
}

output "private-subnet-1" {
  description = "Private subnet 1 ID"
  value = aws_subnet.private-subnet-1.id
}

output "private-subnet-2" {
  description = "Private subnet 2 ID"
  value = aws_subnet.private-subnet-2.id
}