resource "aws_s3_bucket" "reports" {
  bucket = var.reports_bucket_name

  tags = {
    PROJECT_NAME = var.project_name
  }

}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket                  = aws_s3_bucket.reports.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "DeleteReportsAfter90Days"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_notification" "reports" {
  bucket = aws_s3_bucket.reports.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.report_mailer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "reports/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.report_mailer_from_s3]
}

resource "aws_sqs_queue" "report_requests_dlq" {
  name             = "${var.project_name}-report-requests-dlq"
  max_message_size = 1048576

  tags = {
    PROJECT_NAME = var.project_name
  }

}

resource "aws_sqs_queue" "report_requests" {
  name                       = "${var.project_name}-report-requests"
  max_message_size           = 1048576
  visibility_timeout_seconds = 540
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.report_requests_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    PROJECT_NAME = var.project_name
  }
}

resource "aws_iam_role" "report_builder" {
  name = "${var.project_name}-report-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    PROJECT_NAME = var.project_name
  }
}

resource "aws_iam_role_policy" "report_builder_write_reports" {
  name = "WriteReportsToS3"
  role = aws_iam_role.report_builder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.reports.arn}/reports/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "report_builder_vpc_access" {
  role       = aws_iam_role.report_builder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "report_builder_sqs_access" {
  role       = aws_iam_role.report_builder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "report_builder" {
  function_name = "${var.project_name}-report-builder"
  package_type  = "Image"
  image_uri     = var.reports_backend_image_uri
  role          = aws_iam_role.report_builder.arn
  timeout       = 90
  memory_size   = 512
  architectures = ["x86_64"]

  image_config {
    command = ["app.reports.lambda_handler.handler"]
  }

  vpc_config {
    security_group_ids = [var.reports_security_group_id]
    subnet_ids         = var.reports_subnet_ids
  }

  environment {
    variables = {
      DATABASE_URL   = var.database_url
      REPORTS_BUCKET = aws_s3_bucket.reports.id
    }
  }

  tags = {
    PROJECT_NAME = var.project_name
  }

  lifecycle {
    ignore_changes = [environment[0].variables["DATABASE_URL"]]
  }
}

resource "aws_lambda_event_source_mapping" "report_requests" {
  event_source_arn = aws_sqs_queue.report_requests.arn
  function_name    = aws_lambda_function.report_builder.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_iam_role" "report_scheduler" {
  name = "${var.project_name}-report-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    PROJECT_NAME = var.project_name
  }
}

resource "aws_iam_role_policy" "report_scheduler_send_request" {
  name = "SendReportRequest"
  role = aws_iam_role.report_scheduler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.report_requests.arn
    }]
  })
}

resource "aws_scheduler_schedule" "weekly_report" {
  name                         = "${var.project_name}-weekly-report"
  group_name                   = "default"
  schedule_expression          = "cron(0 7 ? * MON *)"
  schedule_expression_timezone = "Europe/Kyiv"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sqs_queue.report_requests.arn
    role_arn = aws_iam_role.report_scheduler.arn
    input    = "{\"week\":null,\"source\":\"schedule\"}"
  }
}

resource "aws_iam_role" "report_mailer" {
  name = "${var.project_name}-report-mailer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    PROJECT_NAME = var.project_name
  }
}

resource "aws_iam_role_policy" "report_mailer_read_send" {
  name = "ReadReportsAndSendEmail"
  role = aws_iam_role.report_mailer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.reports_bucket_name}/reports/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ses:SendRawEmail"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "report_mailer_basic_execution" {
  role       = aws_iam_role.report_mailer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "report_mailer" {
  function_name = "${var.project_name}-report-mailer"
  package_type  = "Image"
  image_uri     = var.reports_backend_image_uri
  role          = aws_iam_role.report_mailer.arn
  timeout       = 30
  memory_size   = 256
  architectures = ["x86_64"]

  image_config {
    command = ["app.reports.mailer_handler.handler"]
  }

  environment {
    variables = {
      REPORT_EMAIL = var.report_email
    }
  }

  tags = {
    PROJECT_NAME = var.project_name
  }

  lifecycle {
    ignore_changes = [environment[0].variables["REPORT_EMAIL"]]
  }
}

resource "aws_lambda_permission" "report_mailer_from_s3" {
  statement_id   = "spry-reports-ReportMailerInvokePermission-OgAIfAn8K8c8"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.report_mailer.function_name
  principal      = "s3.amazonaws.com"
  source_account = var.aws_account_id
  source_arn     = aws_s3_bucket.reports.arn
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.route_table_id]

  tags = {
    PROJECT_NAME = var.project_name
  }
}
