import boto3
import os
import json

transcribe = boto3.client('transcribe')
s3 = boto3.resource('s3')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_key = event['s3_key']
    outputS3 = os.environ['OUTPUT_BUCKET']
    transcript = f'{s3_key}/textract/transcript.json'
    extract = f'{s3_key}/transcript/transcript.txt'

    #Extract transcript from JSON coming from Transcribe service
    content_object = s3.Object(f'{outputS3}', f'{transcript}')
    file_content = content_object.get()['Body'].read().decode('utf-8')
    json_content = json.loads(file_content)
    transcription = json_content['results']['transcripts'][0]['transcript']
    print("The transcipt is: -")
    print(transcription)

    #Save extract to S3
    object = s3.Object(f'{outputS3}', f'{extract}')
    object.put(Body=transcription)

    return event