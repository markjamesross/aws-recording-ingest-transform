resource "aws_lambda_function" "comprehend_check_status" {
  filename = "./src/comprehend-check-status.zip"
  source_code_hash = filebase64sha256("./src/comprehend-check-status.zip")
  function_name = "comprehend-check-status"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "comprehend-check-status.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "comprehend-check-status" }, var.tags)
}
data "archive_file" "comprehend_check_status" {
  type        = "zip"
  source_file = "${path.module}/src/comprehend-check-status.py"
  output_path = "${path.module}/src/comprehend-check-status.zip"
}

resource "aws_iam_role" "iam_for_comprehend_check_status" {
  name               = "iam-for-comprehend-check-status"
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
  tags               = merge({ Name = "iam-for-comprehend-check-status" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_comprehend-check-status" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_comprehend_check_status.name
}

resource "aws_iam_role_policy_attachment" "comprehend2" {
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
  role       = aws_iam_role.iam_for_comprehend_check_status.name
}

resource "aws_cloudwatch_log_group" "comprehend-check-status" {
  name              = "/aws/lambda/comprehend-check-status"
  retention_in_days = 14
}