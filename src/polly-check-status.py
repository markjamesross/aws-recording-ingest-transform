import boto3
import json

polly = boto3.client('polly')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    jobName = event['pollyTaskId']

    response = polly.get_speech_synthesis_task(
      TaskId=jobName
    )

    event['pollyJobStatus'] = response['SynthesisTask']['TaskStatus']

    return event