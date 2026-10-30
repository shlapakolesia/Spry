resource "aws_iam_role" "parser" {
  name = "${var.project_name}-agenda-parser-role"

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

resource "aws_iam_role_policy" "parser_bedrock" {
  name = "InvokeBedrockMantle"
  role = aws_iam_role.parser.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock-mantle:CreateInference"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "parser_basic_execution" {
  role       = aws_iam_role.parser.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "parser" {
  name              = "/aws/lambda/${var.project_name}-agenda-parser"
  retention_in_days = 30

  tags = {
    PROJECT_NAME = var.project_name
  }
}

resource "aws_lambda_function" "parser" {
  function_name = "${var.project_name}-agenda-parser"
  package_type  = "Image"
  image_uri     = var.parser_backend_image_uri
  role          = aws_iam_role.parser.arn
  timeout       = 30
  memory_size   = 512
  architectures = ["x86_64"]

  image_config {
    command = ["app.ai.agenda_lambda.handler"]
  }

  environment {
    variables = {
      PARSER_MODEL         = var.parser_model
      BEDROCK_REGION       = var.bedrock_region
      COGNITO_REGION       = var.cognito_region
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      COGNITO_CLIENT_ID    = var.cognito_client_id
      PARSER_CORS_ORIGINS  = join(",", var.allowed_origins)
    }
  }

  tags = {
    PROJECT_NAME  = var.project_name
    LAB7_MIGRATED = "terraform"
  }

  depends_on = [aws_cloudwatch_log_group.parser]
}

resource "aws_lambda_function_url" "parser" {
  function_name      = aws_lambda_function.parser.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = var.allowed_origins
    allow_methods = ["POST"]
    allow_headers = ["authorization", "content-type"]
    max_age       = 600
  }
}

resource "aws_lambda_permission" "parser_function_url" {
  statement_id           = "spry-ai-live-AgendaParserUrlPermission-SVyHgcqIz8t3"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.parser.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "parser_invoke_via_url" {
  statement_id             = "spry-ai-live-AgendaParserInvokeViaUrlPermission-Gv7iw1mHG0Eu"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.parser.function_name
  principal                = "*"
  invoked_via_function_url = true
}
