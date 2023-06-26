import boto3


def get_caller_identity() -> dict:
    """
    Return the caller identity using the STS client.

    Save the result as a singleton in the gunicorn configuration, or flask g object to avoid multiples API calls
    during the app lifetime.
    """
    sts_client = boto3.client("sts")
    return sts_client.get_caller_identity()


# HACK: A simple way to have a singleton on gunicorn
caller_identity = get_caller_identity()
