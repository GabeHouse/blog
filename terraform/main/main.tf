# ECR repository for your container image
resource "aws_ecr_repository" "blog" {
  name = "blog-app"
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "blog_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to pull from ECR
resource "aws_iam_policy" "lambda_ecr" {
  name        = "lambda_ecr_access"
  description = "Allow Lambda to pull from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.blog.arn
      },
      {
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ecr" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ecr.arn
}

# Lambda function using the container image
resource "aws_lambda_function" "blog_lambda" {
  function_name = "blog-app"
  role          = aws_iam_role.lambda_role.arn
  
  # This is the format for ECR image URIs
  image_uri     = "${aws_ecr_repository.blog.repository_url}:latest"
  package_type  = "Image"
  
  # Configure Lambda resources
  memory_size   = 1024  # Adjust as needed
  timeout       = 30    # Adjust as needed

  # Environment variables for your container
  environment {
    variables = {
      NODE_ENV = "production"
    }
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "blog_api" {
  name          = "blog-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# Default stage for the API
resource "aws_apigatewayv2_stage" "blog_api" {
  api_id      = aws_apigatewayv2_api.blog_api.id
  name        = "$default"
  auto_deploy = true
}

# Integration between API Gateway and Lambda
resource "aws_apigatewayv2_integration" "blog_lambda" {
  api_id           = aws_apigatewayv2_api.blog_api.id
  integration_type = "AWS_PROXY"
  
  integration_uri    = aws_lambda_function.blog_lambda.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Route for all paths
resource "aws_apigatewayv2_route" "blog_route" {
  api_id    = aws_apigatewayv2_api.blog_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.blog_lambda.id}"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.blog_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.blog_api.execution_arn}/*/*"
}

# Output the website URL
output "website_url" {
  value = aws_apigatewayv2_api.blog_api.api_endpoint
}