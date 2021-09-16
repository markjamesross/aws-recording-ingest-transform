#Get details about current AWS session
data "aws_caller_identity" "current" {}
#Get current region
data "aws_region" "current" {}