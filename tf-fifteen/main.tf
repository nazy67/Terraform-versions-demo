resource "aws_db_instance" "rds_db" {
  allocated_storage    = var.storage
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = var.instance_class
  identifier           = "my-rds"
  name                 = "my-rdsdb"
  username             = var.db_username
  password             = random_password.password.result
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%"
}