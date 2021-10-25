resource "aws_lambda_function" "translate" {
  filename = "./src/translate.zip"
  source_code_hash = filebase64sha256("./src/translate.zip")
  function_name = "translate"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "translate.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
      ROLE_ARN = aws_iam_role.iam_for_translate.arn
    }
  }
  tags = merge({ Name = "translate" }, var.tags)
}
data "archive_file" "translate" {
  type        = "zip"
  source_file = "${path.module}/src/translate.py"
  output_path = "${path.module}/src/translate.zip"
}

resource "aws_iam_role" "iam_for_translate" {
  name               = "iam-for-translate"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "translate.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge({ Name = "iam-for-translate" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_translate" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_translate.name
}

resource "aws_iam_role_policy_attachment" "translate" {
  policy_arn = "arn:aws:iam::aws:policy/TranslateFullAccess"
  role       = aws_iam_role.iam_for_translate.name
}

resource "aws_cloudwatch_log_group" "translate" {
  name              = "/aws/lambda/translate"
  retention_in_days = 14
}
