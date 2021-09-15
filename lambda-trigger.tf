resource "aws_lambda_function" "lambda_invoker" {
  filename = "./src/lambda-invoker.zip"
  #source_code_hash = filebase64sha256("./src/lambda-invoker.zip")
  function_name = "lambda-invoker"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "lambda-invoker.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      STEP_FUNCTION_ARN = "10"
    }
  }
  tags = merge({ Name = "lambda-invoker" }, var.tags)
}
data "archive_file" "lambda_invoker" {
  type        = "zip"
  source_file = "${path.module}/src/lambda-invoker.py"
  output_path = "${path.module}/src/lambda-invoker.zip"
}

resource "aws_iam_role" "iam_for_lambda_invoker" {
  name               = "iam-for-lambda-invoker"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge({ Name = "iam-for-lambda-invoker" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_lambda_invoker" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_lambda_invoker.name
}

resource "aws_iam_role_policy_attachment" "stepfunctions" {
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
  role       = aws_iam_role.iam_for_lambda_invoker.name
}

resource "aws_cloudwatch_log_group" "lambda_invoker" {
  name              = "/aws/lambda/iam-for-lambda-invoker"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "Allow_S3_to_invoke_Lambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_invoker.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload.arn
}