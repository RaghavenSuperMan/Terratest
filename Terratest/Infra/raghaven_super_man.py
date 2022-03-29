import json
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Raghaven Super Man!'),
        "headers": {
            "Content-Type": "text/html; charset=utf-8"
        }
    }