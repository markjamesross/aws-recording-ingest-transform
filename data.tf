#Get details about current AWS session
data "aws_caller_identity" "current" {}
#Get current region
data "aws_region" "current" {}

#IAM policy Document for Lambda Invoker
data "aws_iam_policy_document" "lambda_invoker" {
  statement {
    sid = "LambdaInvoker"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.id}:role/*",
    ]

    effect = "Allow"
  }
}