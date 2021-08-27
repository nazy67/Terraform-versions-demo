output "rds_db_name" {
  value = aws_db_instance.rds_db.password
}

output "rds_db_username" {
  value = aws_db_instance.rds_db.username
}