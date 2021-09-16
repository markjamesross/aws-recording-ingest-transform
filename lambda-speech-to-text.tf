resource "aws_lambda_function" "speech_to_text" {
  filename = "./src/speech-to-text.zip"
  source_code_hash = filebase64sha256("./src/speech-to-text.zip")
  function_name = "speech-to-text"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "speech-to-text.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "speech-to-text" }, var.tags)
}
data "archive_file" "speech_to_text" {
  type        = "zip"
  source_file = "${path.module}/src/speech-to-text.py"
  output_path = "${path.module}/src/speech-to-text.zip"
}

resource "aws_iam_role" "iam_for_speech_to_text" {
  name               = "iam-for-speech-to-text"
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
  tags               = merge({ Name = "iam-for-speech-to-text" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_speech_to_text" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
  role       = aws_iam_role.iam_for_speech_to_text.name
}

resource "aws_iam_role_policy_attachment" "transcribe" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess"
  role       = aws_iam_role.iam_for_speech_to_text.name
}

resource "aws_cloudwatch_log_group" "speech_to_text" {
  name              = "/aws/lambda/speech-to-text"
  retention_in_days = 14
}