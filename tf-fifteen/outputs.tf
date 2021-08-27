output "rds_db_password" {
  value = aws_db_instance.rds_db.password
  sensitive = true
}

output "rds_db_username" {
  value = aws_db_instance.rds_db.username
}