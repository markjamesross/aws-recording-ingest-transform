resource "aws_lambda_function" "comprehend" {
  filename = "./src/comprehend.zip"
  source_code_hash = filebase64sha256("./src/comprehend.zip")
  function_name = "comprehend"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "comprehend.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
      ROLE_ARN = aws_iam_role.iam_for_comprehend.arn
    }
  }
  tags = merge({ Name = "comprehend" }, var.tags)
}
data "archive_file" "comprehend" {
  type        = "zip"
  source_file = "${path.module}/src/comprehend.py"
  output_path = "${path.module}/src/comprehend.zip"
}

resource "aws_iam_role" "iam_for_comprehend" {
  name               = "iam-for-comprehend"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "comprehend.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge({ Name = "iam-for-comprehend" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_comprehend" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_comprehend.name
}

resource "aws_iam_role_policy_attachment" "comprehend" {
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
  role       = aws_iam_role.iam_for_comprehend.name
}

resource "aws_cloudwatch_log_group" "comprehend" {
  name              = "/aws/lambda/comprehend"
  retention_in_days = 14
}
