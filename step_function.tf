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
      "Next": "WaitForTranscribe"
    },
    "WaitForTranscribe": {
      "Type": "Wait",
      "Seconds": 60,
      "Next": "CheckTranscribe"
    },
    "CheckTranscribe": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.transcribe_check_status.arn}",
      "Next": "TranscribeComplete?"
    },
    "TranscribeComplete?" : {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.transcriptJobStatus",
          "StringEquals": "FAILED",
          "Next": "TranscribeJobFailed"
        },
        {
          "Variable": "$.transcriptJobStatus",
          "StringEquals": "COMPLETED",
          "Next": "ExtractText"
        }
      ],
      "Default": "WaitForTranscribe"
    },
    "ExtractText": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.extract_text.arn}",
      "Next": "Parrallel"
    },
    "Parrallel": {
      "Type": "Parallel",
      "End": true,
      "Branches": [
        {
          "StartAt": "Comprehend",
          "States": {
            "Comprehend": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.comprehend.arn}",
              "Next": "WaitForComprehend"
            },
            "WaitForComprehend": {
              "Type": "Wait",
              "Seconds": 60,
              "Next": "CheckComprehend"
            },
            "CheckComprehend": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.comprehend_check_status.arn}",
              "Next": "ComprehendComplete?"
            },
            "ComprehendComplete?" : {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.comprehendJobStatus",
                  "StringEquals": "FAILED",
                  "Next": "ComprehendJobFailed"
                },
                {
                  "Variable": "$.comprehendJobStatus",
                  "StringEquals": "COMPLETED",
                  "Next": "ComprehendComplete"
                }
              ],
              "Default": "WaitForComprehend"
            },
            "ComprehendJobFailed": {
              "Type": "Fail",
              "Cause": "Job Failed",
              "Error": "Comprehend job failed"
            },
            "ComprehendComplete": {
              "Type": "Succeed"
            }
          }
        },
        {
          "StartAt": "Translate",
          "States": {
            "Translate": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.translate.arn}",
              "Next" : "WaitforTranslate"
            },
            "WaitforTranslate": {
              "Type": "Wait",
              "Seconds": 60,
              "Next": "CheckTranslate"
            },
            "CheckTranslate": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.translate_check_status.arn}",
              "Next": "TranslateComplete?"
            },
            "TranslateComplete?" : {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.translateJobStatus",
                  "StringEquals": "FAILED",
                  "Next": "TranslateJobFailed"
                },
                {
                  "Variable": "$.translateJobStatus",
                  "StringEquals": "COMPLETED",
                  "Next": "Polly"
                }
              ],
              "Default": "WaitforTranslate"
            },
            "TranslateJobFailed": {
              "Type": "Fail",
              "Cause": "Job Failed",
              "Error": "Translate job failed"
            },
            "Polly": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.polly.arn}",
              "Next": "WaitforPolly"
            },
            "WaitforPolly": {
              "Type": "Wait",
              "Seconds": 60,
              "Next": "CheckPolly"
            },
            "CheckPolly": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.polly_check_status.arn}",
              "Next": "PollyComplete?"
            },
            "PollyComplete?" : {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.pollyJobStatus",
                  "StringEquals": "failed",
                  "Next": "PollyJobFailed"
                },
                {
                  "Variable": "$.pollyJobStatus",
                  "StringEquals": "completed",
                  "Next": "PollyComplete"
                }
              ],
              "Default": "WaitforPolly"
            },
            "PollyJobFailed": {
              "Type": "Fail",
              "Cause": "Job Failed",
              "Error": "Polly job failed"
            },
            "PollyComplete": {
              "Type": "Succeed"
            }
          }
        }
      ]
    },
    "TranscribeJobFailed": {
      "Type": "Fail",
      "Cause": "Job Failed",
      "Error": "Transcribe job failed"
    }
  }
}
EOF
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