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
      "Resource": "${aws_lambda_function.speech_to_text.arn}",
      "Next": "Wait"
    },
    "Wait": {
    "Type": "Wait",
    "Seconds": 10,
    "Next": "CheckTranscribe"
    },
    "CheckTranscribe": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.check_status.arn}",
      "ResultPath": "$.CheckTranscribe",
      "Next": "TranscirbeComplete?"
    },
    "TranscirbeComplete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.CheckTranscribe.input.CheckTranscribe.TranscriptionJobStatus",
          "StringEquals": "Complete",
          "Next": "Complete"
        }
      ],
      "Default": "Wait"
    },
    "Complete": {
      "Type": "Succeed"
    }
  }
}
EOF
/*,
    "Translate": {
      "Type": "Task",
      "Resource": "",
      "Next": "Comprehend"
    },
    "Comprehend": {
      "Type": "Task",
      "Resource": "",
      "Next": "Polly"
    },
    "Polly": {
      "Type": "Task",
      "Resource": "",
      "End": true
    }*/
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

data "aws_iam_policy_document" "state_lambda_invoke" {
  statement {
    sid = "1"

    actions = [
      "lambda:InvokeFunction",
      "transcribe:*",
    ]

    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*",
      "arn:aws:transcribe:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

resource "aws_iam_policy" "state_lambda_invoke" {
  name        = "state-lambda-invoke"
  path        = "/"
  description = "Policy to allow step function to invoke Lambdas"

  policy = data.aws_iam_policy_document.state_lambda_invoke.json
}

resource "aws_iam_role_policy_attachment" "state_lambda_invoke" {
  policy_arn = aws_iam_policy.state_lambda_invoke.arn
  role       = aws_iam_role.iam_for_step_function.name
}