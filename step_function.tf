resource "aws_sfn_state_machine" "workflow_step_function" {
  name     = "workflow-step-function"
  role_arn = aws_iam_role.iam_for_step_function.arn

  definition = <<EOF
{
  "Comment": "Step Function to take uploaded audio and convert to text, perform sentinment analysis, translate and convert to speech",
  "StartAt": "Transcribe",
  "States": {
    "Transcribe": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_invoker.arn}",
      "Next": "Translate"
    },
    "Translate": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_invoker.arn}",
      "Next": "Comprehend"
    },
    "Comprehend": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_invoker.arn}",
      "Next": "Polly"
    },
    "Polly": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_invoker.arn}",
      "End": true
    }
  }
}
EOF

#  logging_configuration {
#    log_destination        = "${aws_cloudwatch_log_group.workflow_step_function.arn}:*"
#    include_execution_data = true
#    level                  = "ERROR"
#  }
}

resource "aws_iam_role" "iam_for_step_function" {
  name               = "iam-for-step-function"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags               = merge({ Name = "iam-for-step-function" }, var.tags)
}

resource "aws_iam_role_policy_attachment" "basic_step_function" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_for_step_function.name
}

resource "aws_cloudwatch_log_group" "workflow_step_function" {
  name              = "/aws/states/workflow-step-function"
  retention_in_days = 14
}