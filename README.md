# QCase

## Objective

- Create and EKS cluster on a dedicated VPC using terraform.
- Implement a CD using GitHub Actions.
- Deploy a simple web application.
- Configure a Load balancer and a deployment policy.


## Repository organization:

There are two main directories:

`utils` - Contains python scripts used for deployment and the bootstrap processes.

`infrastructure` - Contains the terraform definitions to build and deploy the infrastructure.


Additionally other directories are created during the bootstrap process:

`venv` - Contains a python *virtualenv* environment used to install all the python requirements. 

`logs` - 


## Configuration
The `configuration.yml` file contains a set of values that can be used to configure the `bootstrap` and `deployment` process.
```yaml
# The idea of this configuration file is to be a single source of truth for the bootstrap scripts and terraform.
project_name: qcase
aws_region: eu-central-1
logs_directory: logs


# the bucket_suffix_name is prefixed with the account_id and region to create the bucket name
# ex: 123456789012-us-west-1-terraform-backend-project_name
terraform:
  state_name: dev
  bucket_suffix_name: terraform-backend-qcase

```

## Prerequisites:

Software:

- python3 and python3-venv packages in Debian/Ubuntu systems or their equivalents.
- terraform 1.5
- GNU make


AWS Configured credentials.


## Bootstrap
The bootstrap target creates a set following set of resources:
- A s3 bucket to be used as a backend storage for terraform state files.

```shell
make bootstrap
```

## Deploy infrastructure

The infrastructure is organized in two directories:
### organization
Organization infrastructure resources. These resources are considered prerequisites for the current project.

### infrastructure
Project infrastructure resources.


```shell
make deploy
```

## CD


## Development

Main Makefile targets
```shell
make

Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	help
			Show this help.
	bootstrap
			Create the virtualenv to run pip-install target.
	pip-install
			Install python dependencies using pip.
	pip-upgrade
			Upgrade python dependencies using pip. This ignore pinning versions in requirements.txt.
			But only updates packages that are in that file.
	pip-pinning
			Like pip freeze but pinning only packages that are in requirements.txt.
			This doesn't include any package that could be present in the virtualenv
			as result of manual installs or resolved dependencies.
	pip-uninstall
			Uninstall python dependencies using pip.
	deploy
			Deploy infrastructure running terraform.
	destroy
			Destroy infrastructure running terraform.
	python-lint
			Run linting tools for python code in the ${UTILS_SRC} directory.
	terraform-lint
			Run linting tools for terraform code in the ${INFRASTRUCTURE} directory.
	lint
			Run linting tools for Python and Terraform code.

```


### Terraform
Inside the `infratructure` directory there are a set of specific make targets to use during the development phase.   
```shell
make

Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	help
			Show this help.
	init
			Run terraform init.
	plan
			Run terraform format, and terraform plan storing the plan for the apply phase.
	plan-destroy
			Run terraform plan -destroy storing the plan for the apply phase.
			A TARGETS variable containing a space separated list of resources can by provided
			to processed and used as targets with -target.
	apply
			Runs terraform apply with a previous created plan.
	deploy
			Runs the init, plan, and apply targets.
	destroy
			Runs terraform destroy.
	fmt
			Runs terraform format updating the needed files.
	validate
			Runs fmt target and terraform validate.
	clean
			Clean saved plans and logs.

```


## TODO:

Investigate how to reuse a GitHub workflows definition to reduce the code duplication.
See: https://docs.github.com/en/actions/using-workflows/reusing-workflows


### Missing pieces:
- EKS Cluster
- CD
- LB configuration.
- Application deployment.
- Deployment configuration.


### Can be improved:

#### At Bootstrap:
- Add a method to remove the s3 bucket when terraform resources are destroyed.
