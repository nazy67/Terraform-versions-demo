resource "aws_db_instance" "rds-db" {
  allocated_storage    = var.storage
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.5"
  instance_class       = var.instance_class
  identifier           = "${var.env}-rds"
  name                 = "my-rdsdb"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids    = [aws_security_group.rds_sg.id]
}