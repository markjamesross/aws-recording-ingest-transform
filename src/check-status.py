import boto3
import json

transcribe = boto3.client('transcribe')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    transcriptJobName = event['s3_key']

    response = transcribe.get_transcription_job(
        TranscriptionJobName=transcriptJobName
    )

    event['transcriptJobStatus'] = response['TranscriptionJob']['TranscriptionJobStatus']

    return event