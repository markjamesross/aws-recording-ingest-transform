resource "aws_lambda_function" "polly" {
  filename = "./src/polly.zip"
  source_code_hash = filebase64sha256("./src/polly.zip")
  function_name = "polly"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "polly.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
      ROLE_ARN = aws_iam_role.iam_for_polly.arn
      ACCOUNT_ID = data.aws_caller_identity.current.id
    }
  }
  tags = merge({ Name = "polly" }, var.tags)
}
data "archive_file" "polly" {
  type        = "zip"
  source_file = "${path.module}/src/polly.py"
  output_path = "${path.module}/src/polly.zip"
}

resource "aws_iam_role" "iam_for_polly" {
  name               = "iam-for-polly"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge({ Name = "iam-for-polly" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_polly" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_polly.name
}

resource "aws_iam_role_policy_attachment" "polly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonPollyFullAccess"
  role       = aws_iam_role.iam_for_polly.name
}

resource "aws_cloudwatch_log_group" "polly" {
  name              = "/aws/lambda/polly"
  retention_in_days = 14
}
