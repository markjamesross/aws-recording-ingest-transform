resource "aws_lambda_function" "polly_check_status" {
  filename = "./src/polly-check-status.zip"
  source_code_hash = filebase64sha256("./src/polly-check-status.zip")
  function_name = "polly-check-status"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "polly-check-status.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "polly-check-status" }, var.tags)
}
data "archive_file" "polly_check_status" {
  type        = "zip"
  source_file = "${path.module}/src/polly-check-status.py"
  output_path = "${path.module}/src/polly-check-status.zip"
}

resource "aws_iam_role" "iam_for_polly_check_status" {
  name               = "iam-for-polly-check-status"
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
  tags               = merge({ Name = "iam-for-polly-check-status" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_polly-check-status" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_polly_check_status.name
}

resource "aws_iam_role_policy_attachment" "polly2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonPollyFullAccess"
  role       = aws_iam_role.iam_for_polly_check_status.name
}

resource "aws_cloudwatch_log_group" "polly-check-status" {
  name              = "/aws/lambda/polly-check-status"
  retention_in_days = 14
}