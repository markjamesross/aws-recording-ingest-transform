resource "aws_lambda_function" "extract_text" {
  filename = "./src/extract-text.zip"
  source_code_hash = filebase64sha256("./src/extract-text.zip")
  function_name = "extract-text"
  role          = aws_iam_role.iam_for_lambda_invoker.arn
  handler       = "extract-text.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.id
    }
  }
  tags = merge({ Name = "extract-text" }, var.tags)
}
data "archive_file" "extract_text" {
  type        = "zip"
  source_file = "${path.module}/src/extract-text.py"
  output_path = "${path.module}/src/extract-text.zip"
}

resource "aws_cloudwatch_log_group" "extract_text" {
  name              = "/aws/lambda/extract-text"
  retention_in_days = 14
}