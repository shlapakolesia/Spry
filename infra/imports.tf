import {
  to = aws_cognito_user_pool.users
  id = "eu-north-1_m4dJRmho3"
}

import {
  to = aws_cognito_identity_provider.google
  id = "eu-north-1_m4dJRmho3:Google"
}

import {
  to = aws_cognito_user_pool_client.frontend
  id = "eu-north-1_m4dJRmho3/1uucla7u51q5an1th1j48hjtbi"
}

import {
  to = aws_cognito_user_pool_domain.login
  id = "spry-auth-lab3-2026"
}

import {
  to = aws_cognito_managed_login_branding.frontend
  id = "eu-north-1_m4dJRmho3,560d4620-1730-4313-94fb-f0fcfab42a09"
}

import {
  to = aws_s3_bucket.reports
  id = "spry-reports-664874246122"
}

import {
  to = aws_s3_bucket_public_access_block.reports
  id = "spry-reports-664874246122"
}

import {
  to = aws_s3_bucket_server_side_encryption_configuration.reports
  id = "spry-reports-664874246122"
}

import {
  to = aws_s3_bucket_lifecycle_configuration.reports
  id = "spry-reports-664874246122"
}

import {
  to = aws_s3_bucket_notification.reports
  id = "spry-reports-664874246122"
}

import {
  to = aws_sqs_queue.report_requests_dlq
  id = "https://sqs.eu-north-1.amazonaws.com/664874246122/spry-report-requests-dlq"
}

import {
  to = aws_sqs_queue.report_requests
  id = "https://sqs.eu-north-1.amazonaws.com/664874246122/spry-report-requests"
}

import {
  to = aws_iam_role.report_builder
  id = "spry-report-builder-role"
}

import {
  to = aws_iam_role_policy.report_builder_write_reports
  id = "spry-report-builder-role:WriteReportsToS3"
}

import {
  to = aws_iam_role_policy_attachment.report_builder_vpc_access
  id = "spry-report-builder-role/arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

import {
  to = aws_iam_role_policy_attachment.report_builder_sqs_access
  id = "spry-report-builder-role/arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

import {
  to = aws_lambda_function.report_builder
  id = "spry-report-builder"
}

import {
  to = aws_lambda_event_source_mapping.report_requests
  id = "b568190d-c5f9-4213-b309-b4a978c65bcd"
}

import {
  to = aws_iam_role.report_scheduler
  id = "spry-report-scheduler-role"
}

import {
  to = aws_iam_role_policy.report_scheduler_send_request
  id = "spry-report-scheduler-role:SendReportRequest"
}

import {
  to = aws_scheduler_schedule.weekly_report
  id = "default/spry-weekly-report"
}

import {
  to = aws_iam_role.report_mailer
  id = "spry-report-mailer-role"
}

import {
  to = aws_iam_role_policy.report_mailer_read_send
  id = "spry-report-mailer-role:ReadReportsAndSendEmail"
}

import {
  to = aws_iam_role_policy_attachment.report_mailer_basic_execution
  id = "spry-report-mailer-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

import {
  to = aws_lambda_function.report_mailer
  id = "spry-report-mailer"
}

import {
  to = aws_lambda_permission.report_mailer_from_s3
  id = "spry-report-mailer/spry-reports-ReportMailerInvokePermission-OgAIfAn8K8c8"
}

import {
  to = aws_vpc_endpoint.s3_gateway
  id = "vpce-005d605ba41ff7bc6"
}

import {
  to = aws_iam_role.parser
  id = "spry-agenda-parser-role"
}

import {
  to = aws_iam_role_policy.parser_bedrock
  id = "spry-agenda-parser-role:InvokeBedrockMantle"
}

import {
  to = aws_iam_role_policy_attachment.parser_basic_execution
  id = "spry-agenda-parser-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

import {
  to = aws_cloudwatch_log_group.parser
  id = "/aws/lambda/spry-agenda-parser"
}

import {
  to = aws_lambda_function.parser
  id = "spry-agenda-parser"
}

import {
  to = aws_lambda_function_url.parser
  id = "spry-agenda-parser"
}

import {
  to = aws_lambda_permission.parser_function_url
  id = "spry-agenda-parser/spry-ai-live-AgendaParserUrlPermission-SVyHgcqIz8t3"
}

import {
  to = aws_lambda_permission.parser_invoke_via_url
  id = "spry-agenda-parser/spry-ai-live-AgendaParserInvokeViaUrlPermission-Gv7iw1mHG0Eu"
}
