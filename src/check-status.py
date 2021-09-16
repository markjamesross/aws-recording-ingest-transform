import boto3
import json

transcribe = boto3.client('transcribe')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    transcriptionJobName = event['TranscriptionJobName']

    response = transcribe.get_transcription_job(
        TranscriptionJobName=transcriptionJobName
    )

    event['TranscriptionJobStatus'] = response['TranscriptionJob']['TranscriptionJobStatus']

    return event