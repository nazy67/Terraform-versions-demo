variable "db_username" {
  type        = string
  description = "this is ami of the EC2 instance"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "this is instance type of EC2"
  default     = "password123"
}

variable "storage" {
  type        = "string"
  description = "this is instance type of EC2"
  default     = "10"
}

variable "instance_class" {
  type        = string
  description = "this is instance type of EC2"
  default     = "db.t2.micro"
}

variable "env" {
  type        = string
  description = "this is env"
  default     = "dev"
}