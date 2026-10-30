variable "aws_account_id" {
  type    = string
  default = "664874246122"
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "frontend_url" {
  type = string
}

variable "cognito_domain_prefix" {
  type = string
}

variable "google_client_id" {
  type = string
}

variable "google_client_secret" {
  type      = string
  sensitive = true
}

variable "report_email" {
  type      = string
  sensitive = true
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "reports_backend_image_uri" {
  type = string
}

variable "parser_backend_image_uri" {
  type = string
}

variable "parser_model" {
  type = string
}

variable "bedrock_region" {
  type = string
}

variable "cognito_region" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "allowed_origins" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "reports_security_group_id" {
  type = string
}

variable "reports_subnet_ids" {
  type = list(string)
}

variable "reports_bucket_name" {
  type = string
}
