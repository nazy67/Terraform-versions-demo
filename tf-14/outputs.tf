output "rds_db_name" {
  value = aws_db_instance.rds-db.password
}

output "rds_db_username" {
  value = aws_db_instance.rds-db.username
}