"""
Calculate the SHA256 hash for the content of each file in the target directory

This is used to get a json dict to be used with the terraform external data source/

See: https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external

e.g.:
command: python3 sha256sum-dir-content.py --directory charts/qweb --output json --pretty-print
output:
{
  "bb987e6a8ef45a99255d1d632812482d5f0f3255ea841520b4d90342df5fe2b3": "charts/qweb/.helmignore",
  "e9777e62e15a789d3c1da0c7a3ddf6aca1956ed299a3a9cec5f70a94859a9b21": "charts/qweb/values.yaml",
  "6f21a55170a6115ea5fe1fc0f321cd6009e9b9b84e684d4af09a32670bb4bfd0": "charts/qweb/Chart.yaml",
  "1f926a02e9bede5bcb8d58043c5f0882cc1b672badf49a73d83fa8389ca9267a": "charts/qweb/templates/service.yaml",
  "2372f31a93af5aa21109d85510f45e84850b0eac6e1fc78352dc0a3bf75c4ed7": "charts/qweb/templates/deployment.yaml",
  "766882bd949af6bd435ebe5df9f4c9e27a3bee4f6056159e8068fb61909ff732": "charts/qweb/templates/NOTES.txt",
  "9940d78c8f6f858a0b490fb710696f9b7e66a08657fc32f2b04257bd0dd9542d": "charts/qweb/templates/hpa.yaml",
  "2688532ed0028fd24ace90463362919b84bc484da386cbc0e0bbf96963dd6caf": "charts/qweb/templates/ingress.yaml",
  "fac50e17356defbb63a3c23a88bea77dafa211672b69ed2e3df31aa8ae901104": "charts/qweb/templates/_helpers.tpl",
  "57133898aa02f488644b19e0af51ae8106af59fd213f34a54d1a6df3f861e672": "charts/qweb/templates/serviceaccount.yaml",
  "94574e1c7bd6c129c83df7c44240b120bd1aa6436076fd39b2b8d9a7dcf1b0b7": "charts/qweb/templates/tests/test-connection.yaml"
}

"""

import errno
import json
import os
import sys
from argparse import ArgumentParser
from hashlib import sha256
from pathlib import Path


def sha256sum_dir_content(directory: Path) -> dict[str, str]:
    """
    Calculate the SHA256 hash for the content of each file in the target directory, represented as a dict.
    """
    data = {}
    for ppath in directory.rglob("*"):
        if ppath.is_file():
            content = ppath.read_bytes()
            data[sha256(content).hexdigest()] = ppath.as_posix()

    return data


def p_error(error: int, filename: str, quiet: bool = True) -> int:
    """
    Print the str error for an error code and return the error code.

    :param error: Error code defined in the errno module.
    :param filename: associated to the error.
    :param quiet: if is true, print the error message to the stderr.

    :return: ecode: valid error code
    """
    assert error in errno.errorcode, "The error number must be defined in in the errno module. See man errno"
    if not quiet:
        print(f"{os.strerror(error)}: '{filename}'", file=sys.stderr)

    return error


def main() -> int:
    """
    Main function for parsing arguments and print results.

    :return: exit status code. 0 if Success or >= 1 otherwise Fail.
    """
    task = Path(__file__).stem
    parser = ArgumentParser(description=f"{task}".title())
    required = parser.add_argument_group("required arguments")
    required.add_argument("-d", "--directory", help="Target directory.", required=True, type=str)
    parser.add_argument(
        "-o",
        "--output",
        help="Output type, Supported values are 'text' and 'json'. Default: text",
        default="text",
        type=str,
        choices=["text", "json"],
    )
    parser.add_argument(
        "-p", "--pretty-print", action="store_true", help="Pretty print json data. Ignored if the output is not json"
    )
    parser.add_argument("-q", "--quiet", action="store_true", help="Don't print error messages.")

    options = parser.parse_args()
    directory = Path(options.directory)

    if not directory.exists():
        return p_error(errno.ENOENT, directory.as_posix(), options.quiet)

    if not directory.is_dir():
        return p_error(errno.ENOTDIR, directory.as_posix(), options.quiet)

    hash_table = sha256sum_dir_content(directory)

    if options.output == "json" and options.pretty_print:
        print(json.dumps(hash_table, indent=4))
    elif options.output == "json":
        print(json.dumps(hash_table))
    else:  # default output is text
        print("\n".join(f"{shash}  {filename}" for shash, filename in hash_table.items()))

    return 0


if __name__ == "__main__":
    sys.exit(main())
