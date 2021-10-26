import boto3
import json

comprehend = boto3.client('comprehend')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    jobName = event['comprehendJobId']

    response = comprehend.describe_key_phrases_detection_job(
      JobId=jobName
    )

    event['comprehendJobStatus'] = response['KeyPhrasesDetectionJobProperties']['JobStatus']

    return event