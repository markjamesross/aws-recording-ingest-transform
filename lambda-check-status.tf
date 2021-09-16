resource "aws_lambda_function" "check_status" {
  filename = "./src/check-status.zip"
  source_code_hash = filebase64sha256("./src/check-status.zip")
  function_name = "check-status"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "check-status.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "check-status" }, var.tags)
}
data "archive_file" "check_status" {
  type        = "zip"
  source_file = "${path.module}/src/check-status.py"
  output_path = "${path.module}/src/check-status.zip"
}

resource "aws_iam_role" "iam_for_check_status" {
  name               = "iam-for-check-status"
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
  tags               = merge({ Name = "iam-for-check-status" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_check-status" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_check_status.name
}

resource "aws_iam_role_policy_attachment" "transcribe2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess"
  role       = aws_iam_role.iam_for_check_status.name
}

resource "aws_cloudwatch_log_group" "check-status" {
  name              = "/aws/lambda/check-status"
  retention_in_days = 14
}