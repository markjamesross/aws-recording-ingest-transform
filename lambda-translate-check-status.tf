resource "aws_lambda_function" "translate_check_status" {
  filename = "./src/translate-check-status.zip"
  source_code_hash = filebase64sha256("./src/translate-check-status.zip")
  function_name = "translate-check-status"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "translate-check-status.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "translate-check-status" }, var.tags)
}
data "archive_file" "translate_check_status" {
  type        = "zip"
  source_file = "${path.module}/src/translate-check-status.py"
  output_path = "${path.module}/src/translate-check-status.zip"
}

resource "aws_iam_role" "iam_for_translate_check_status" {
  name               = "iam-for-translate-check-status"
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
  tags               = merge({ Name = "iam-for-translate-check-status" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_translate-check-status" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_translate_check_status.name
}

resource "aws_iam_role_policy_attachment" "translate2" {
  policy_arn = "arn:aws:iam::aws:policy/TranslateFullAccess"
  role       = aws_iam_role.iam_for_translate.name
}

resource "aws_cloudwatch_log_group" "translate-check-status" {
  name              = "/aws/lambda/translate-check-status"
  retention_in_days = 14
}