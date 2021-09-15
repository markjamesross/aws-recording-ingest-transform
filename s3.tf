#Create S3 bucket to upload files for processing
resource "aws_s3_bucket" "upload" {
  #Give bucket name with AWS account ID prefix
  bucket        = "${data.aws_caller_identity.current.account_id}-upload-bucket"
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = merge({ Name = "${data.aws_caller_identity.current.account_id}-upload-bucket" }, var.tags)
}

#Create S3 bucket to present files that have been processed back to the user
resource "aws_s3_bucket" "processed" {
  #Give bucket name with AWS account ID prefix
  bucket        = "${data.aws_caller_identity.current.account_id}-processed-bucket"
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = merge({ Name = "${data.aws_caller_identity.current.account_id}-processed-bucket" }, var.tags)
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_invoker.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_function.lambda_invoker]
}