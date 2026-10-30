output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}

output "cognito_domain" {
  value = "https://${var.cognito_domain_prefix}.auth.${var.aws_region}.amazoncognito.com"
}

output "reports_bucket_name" {
  value = aws_s3_bucket.reports.id
}

output "report_requests_queue_url" {
  value = aws_sqs_queue.report_requests.url
}

output "report_requests_dlq_url" {
  value = aws_sqs_queue.report_requests_dlq.url
}

output "agenda_parser_function_url" {
  value = aws_lambda_function_url.parser.function_url
}
