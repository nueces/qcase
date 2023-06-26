import json

import boto3
from botocore.exceptions import ClientError
from botocore.exceptions import BotoCoreError


def get_caller_identity() -> dict:
    """
    Return the caller identity using the STS client.

    Save the result as a singleton in the gunicorn configuration, or flask g object to avoid multiples API calls
    during the app lifetime.
    """
    sts_client = boto3.client("sts")
    try:
        response = sts_client.get_caller_identity()
    except BotoCoreError as bex:
        response = json.dumps({"BotoCoreError": str(bex)})
    except ClientError as bex:
        response = json.dumps({"ClientError": str(bex)})
    except Exception as gex:
        response = json.dumps({"Exception": str(gex)})
    return response


# HACK: A simple way to have a singleton on gunicorn
caller_identity = get_caller_identity()
