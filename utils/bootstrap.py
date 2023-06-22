"""
Bootstrap tasks for creating basic resources need to use terraform and ansible.
"""
import logging
import os.path
import sys
from argparse import ArgumentParser
from logging import Logger
from pathlib import Path

import boto3
import yaml
from botocore.exceptions import ClientError


def create_bucket(logger: Logger, bucket_name: str, region_name: str, enable_versioning: bool = True) -> bool:
    """
    Create an S3 bucket in a specified region.

    :param logger: A logger object.
    :param bucket_name: Bucket name to create.
    :param region_name: Region to create bucket in, e.g., 'us-west-2'.
    :param enable_versioning: default True.
    :return: True if bucket created or if it already exists, else False.
    """
    result = False
    s3_client = boto3.client("s3", region_name=region_name)

    try:
        s3_client.create_bucket(
            Bucket=bucket_name,
            CreateBucketConfiguration={"LocationConstraint": region_name},
        )
    except ClientError as error:
        try:
            result = error.response["Error"]["Code"] == "BucketAlreadyOwnedByYou"
            if result:
                logger.info("BucketAlreadyOwnedByYou: Bucket already exist")
            else:
                logger.error(error)
        except KeyError:
            logger.error(error)
    else:
        result = True

    if result and enable_versioning:
        try:
            response = s3_client.get_bucket_versioning(Bucket=bucket_name)
        except ClientError as error:
            logger.error(error)
            result = False
        else:
            status = response.get("Status", "NotSet")
            if status == "Enabled":
                logger.info("Versioning on bucket %s already enabled", bucket_name)
            elif status in ("NotSet", "Disabled"):
                logger.info(
                    "Enabling versioning on bucket %s. Previous versioning status: %s",
                    bucket_name,
                    status,
                )
                try:
                    response = s3_client.put_bucket_versioning(
                        Bucket=bucket_name,
                        VersioningConfiguration={"Status": "Enabled"},
                    )
                except ClientError as error:
                    logger.error(error)
                    logger.error(response)
                    result = False

    return result


def execute_tasks(logger: Logger, config: dict) -> int:
    """
    Execute the task and return a valid posix status code.

    logger: A logger object.
    config: A dictionary containing the project configurations.
    :return: exit status code. 0 Success, 1 Fail.
    """
    success = []

    logger.info("Starting task")

    region = config.get("aws_region")
    sts_client = boto3.client("sts", region_name=region)
    account_id = sts_client.get_caller_identity().get("Account")
    # TODO: Compliance. Validate name convention.
    bucket_name = f"{account_id}-{region}-{config['terraform']['bucket_suffix_name']}"

    logger.info("Creating bucket: %s", bucket_name)
    success.append(create_bucket(logger, bucket_name, region))

    if not all(success):
        logger.error("Some errors occurs during the bootstrap process, please review the logs for more details.")

    logger.info("Finish")
    # POSIX standard status code
    return 0 if all(success) else 1


def main():
    """
    Run all the task in the bootstrap script.

    :return: exit status code. 0 Success, 1 Fail.
    """
    # the task name is based in the filename
    task = os.path.splitext(os.path.basename(__file__))[0]
    formatter = logging.Formatter(
        fmt="%(asctime)s:%(name)s:%(levelname)s:%(message)s",
        datefmt="%Y-%m-%d %H%M%S",
    )

    logger = logging.getLogger(task)
    logger.setLevel(logging.DEBUG)

    console = logging.StreamHandler()
    console.setFormatter(formatter)
    console.setLevel(logging.INFO)

    logger.addHandler(console)

    parser = ArgumentParser(description=f"{task}".title())
    required = parser.add_argument_group("required arguments")
    required.add_argument("--configuration", help="Project configuration file.", required=True, type=str)
    options = parser.parse_args()
    config_file = Path(options.configuration)
    if not config_file.exists():
        logger.error("The provided configuration file: '%s', does not exist", config_file.absolute())
        sys.exit(1)
    elif not config_file.is_file():
        logger.error("The provided configuration file: '%s', is not a file", config_file.absolute())
        sys.exit(1)

    with config_file.open("r", encoding="utf-8") as fdc:
        config = yaml.safe_load(fdc)

    # BASIC CONFIG
    basic_cfg = {
        "logs_directory": None,
    }
    for key in basic_cfg:
        try:
            basic_cfg[key] = config.get(key)
        except KeyError:
            logger.error("The key:'%s', must be set in the configuration file.", key)
            raise

    # DOC: We expect that the configuration file is located in the project root directory
    # and that the logs directory is reachable from that directory.
    logs_directory = config_file.parent.joinpath(basic_cfg["logs_directory"])
    if not logs_directory.exists():
        logger.info("Creating the logs directory: '%s'.", basic_cfg["logs_directory"])
        logs_directory.mkdir()
    elif not logs_directory.is_dir():
        logger.error("The configure logs_directory: '%s', is not a directory.", basic_cfg["logs_directory"])
        sys.exit(1)

    logfile = logging.FileHandler(logs_directory.joinpath(f"{task}.log"))
    logfile.setFormatter(formatter)
    logfile.setLevel(logging.DEBUG)
    logger.addHandler(logfile)

    return execute_tasks(logger, config)


if __name__ == "__main__":
    sys.exit(main())
