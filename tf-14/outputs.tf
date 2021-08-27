output "rds_db_password" {
  value = aws_db_instance.rds-db.password
}

output "rds_db_username" {
  value = aws_db_instance.rds-db.username
}