"""
Bootstrap tasks for creating basic resources need to use terraform and ansible.
"""
import logging
import os.path
import stat
import sys
from datetime import datetime
from argparse import ArgumentParser
from logging import Logger
from pathlib import Path

import boto3
import yaml
from botocore.exceptions import ClientError


def create_bucket(logger: Logger, bucket_name: str, region_name: str, enable_versioning: bool = True) -> bool:
    """
    Create an S3 bucket in a specified region.

    :param logger: An object logger.
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


def create_key_pair(logger: Logger, keypair_name: str, parent_path: Path, region_name: str) -> bool:
    """
    Create a Keypair in a specified region, and store the KeyMaterial/PrivateKey in the parent_path location.

    :param logger: An object logger.
    :param keypair_name: String, resource name to be created.
    :param parent_path: Path, where the new key would be storage in the local machine.
    :param region_name: String, Region to create bucket in, e.g., 'us-west-2'.
    :return: Bool, True if bucket created or if it already exists, else False.
    """
    result = False
    ec2_client = boto3.client("ec2", region_name=region_name)
    file_path = parent_path.joinpath(f"{keypair_name}.pem")

    st_mode = parent_path.stat().st_mode
    # Check if a directory and with  permissions for reading, writing and execute only for the owner user.
    if st_mode != stat.S_IFDIR | stat.S_IRWXU:
        logger.warning(
            "Current permissions for the vault directory '%s' are considered insecure '%s'",
            parent_path,
            stat.filemode(st_mode),
        )
        logger.info(
            "Updating permissions for the vault directory '%s' to '%s'",
            parent_path,
            stat.filemode(stat.S_IFDIR | stat.S_IRWXU),
        )
        parent_path.chmod(stat.S_IFDIR | stat.S_IRWXU)
    try:
        response = ec2_client.create_key_pair(KeyName=keypair_name, KeyType="rsa", KeyFormat="pem")
    except ClientError as error:
        try:
            result = error.response["Error"]["Code"] == "InvalidKeyPair.Duplicate"
            if result:
                logger.info("keypair '%s' already exist.", keypair_name)
                if not file_path.exists():
                    logger.warning("Keypair is not present in the Vault location: %s.", parent_path.absolute())
            else:
                logger.error(error)
        except KeyError:
            logger.error(error)
    else:
        if file_path.exists():
            # Don't override the private key in case it exist. But create a backup of the existing file.
            backup_time = datetime.now().strftime("%Y%m%d-%H%M%S")
            backup_path = parent_path.joinpath(f"{keypair_name}.pem-{backup_time}.bck")
            logger.warning("key file '%s' already exist.", file_path)
            logger.info("Creating backup '%s'.", backup_path)
            file_path.rename(backup_path)

        logger.info("Saving private key to '%s'", file_path)
        # This should fail in case the file still exist.
        with file_path.open("x") as fdk:
            file_path.chmod(stat.S_IWUSR | stat.S_IRUSR)
            result = bool(fdk.write(response["KeyMaterial"]))

    return result


def execute_tasks(logger: Logger, config: dict) -> int:
    """
    Execute the task and return a valid posix status code.

    logger: An object logger.
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

    logger.info("Creating create keypair: %s", config.get('key_name'))
    success.append(create_key_pair(logger, config.get("key_name"), Path(config.get("vault_directory")), region))

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
        "vault_directory": None,
        "key_name": None,
    }
    for key in basic_cfg:
        try:
            basic_cfg[key] = config.get(key)
        except KeyError:
            logger.error("The key:'%s', must be set in the configuration file.", key)
            raise

    # DOC: We expect that the configuration file is located in the project root directory
    # and that the other directories are relatives to that directory. Say that you can always can use the path ../
    # to store objects outside the project directory.
    directories = {key: value for key, value in basic_cfg.items() if key.endswith("_directory")}
    for key, value in directories.items():
        assert isinstance(value, str)
        directory = config_file.parent.joinpath(value)
        if not directory.exists():
            logger.info("Creating the '%s' directory: '%s'.", key.removesuffix("_directory"), value)
            directory.mkdir()
        elif not directory.is_dir():
            logger.error("The configured '%s': '%s', is not a directory.", key, value)
            sys.exit(1)

    logfile = logging.FileHandler(config_file.parent.joinpath(directories["logs_directory"], f"{task}.log"))
    logfile.setFormatter(formatter)
    logfile.setLevel(logging.DEBUG)
    logger.addHandler(logfile)

    return execute_tasks(logger, config)


if __name__ == "__main__":
    sys.exit(main())
