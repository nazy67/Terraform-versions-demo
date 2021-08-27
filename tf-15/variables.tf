variable "db_username" {
  type        = string
  description = "this is rds db user username"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "this is rds user db password"
  default     = "password123"
  // sensitive  = true
}

variable "storage" {
  type        = "string"
  description = "this is rds storage size"
  default     = "10"
}

variable "instance_class" {
  type        = string
  description = "this is instance type of EC2"
  default     = "db.t2.micro"
}