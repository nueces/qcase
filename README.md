# QCase

## Objective

- Create and EKS cluster on a dedicated VPC using terraform.
- Implement a CD using GitHub Actions.
- Deploy a simple web application.
- Configure a Load balancer and a deployment policy.

## Repository:

GitHub: https://github.com/nueces/qcase/
 

## Project organization overview


 Main directories:

`utils` - Contains python scripts used for the bootstrap processes.

`infrastructure` - Contains the terraform definitions to build and deploy the infrastructure.

`organization` - Contains the terraform definitions to build the organization infrastructure.

`applications` - Contains the application source code.

`charts` - Contains the Helm charts definition to deploy the container image application to the Kubernetes cluster.  


Additionally other directories are created during the bootstrap process:

`venv` - Contains a python *virtualenv* environment used to install all the python requirements. 

`logs` - Where the logs are created 



## Project configuration

The `configuration.yml` file contains a set of values that can be used to configure the `bootstrap` and `deployment`
process.

```yaml
---
# The idea of this configuration file is to be a single source of truth for the bootstrap scripts and terraform.
project_name: qcase
aws_region: eu-central-1
logs_directory: logs
vault_directory: vault  # Be sure that this path is present in the .gitignore file.
key_name: qcase  # Keypair to be used in worker nodes instances.

# the bucket_suffix_name is prefixed with the account_id and region to create the bucket name
# ex: 123456789012-eu-central-1-terraform-backend-project_name
terraform:
  bucket_suffix_name: terraform-backend-qcase
```


## Prerequisites:

Software:

- python3 and python3-venv packages in Debian/Ubuntu systems or their equivalents.
- terraform 1.5
- GNU make


AWS Configured credentials for GitHub Actions. See **Secrets and variables** in the CI/CD section.


## Bootstrap

The bootstrap target creates a set following set of resources:
 - A s3 bucket to be used as a backend storage for terraform state files.
 - A keypair that would be stored in the configured `vault_directory`. This keypair is created in this stage,
   because using terraform instead, would end with the cryptographical material being stored in the tfstate file.


To run the process just execute:
```shell
make bootstrap
```

## Project Development

Main Makefile targets
```shell
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
	yaml-lint
			Run linting tools for yaml code in the .github directory and the configuration.yml, and .yamllint.yml files.
	lint
			Run linting tools for Python and Terraform code.
	kubeconfig
			Generate a local kubectl configuration file to connect to the k8s cluster.
	workflow-list
			List all the configured workflows
	workflow-run
			Run a workflow from the list [Interactive]
	workflow-enable
			Enable a workflow from the list [Interactive]
	workflow-enable-all
			Enable all the workflows in the project
	workflow-disable
			Disable a workflow from the list [Interactive]
	workflow-disable-all
			Disable all the workflows in the project

```


### Organization Infrastructure / Terraform

Inside the directory `organization` are the set of resources definitions that are typically built as pre-requisite for a
specific project.
In a real-life scenario these resources are managed in a separated repository.


### Project Infrastructure / Terraform

Inside the directory `infratructure` directory there are two subdirectories.
- `main-resources` for deploying projects resources like VPC, EKS cluster, etc.
- `kubernets-resources` for deploying Kubernetes resources, like Helm chars, controllers, and AWS resources needed for
   that like IAM roles and policies.


#### Makefile
Each directory that contains terraform files has a Makefile with a set of specific targets to use during the development
phase.

```shell
Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	help
			Show this help.
	init
			Run terraform init.
	reconfigure
			Run terraform init --reconfigure.
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


### Application development

The application development has place inside the directory `applications/qweb`, and the source code is stored in 
the subdirectory `src`.

There is also a Makefile with the following targets used for development and for the CI/CD process.
```shell
Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	debug
			Used for development.
	help
			Show this help.
	pip-pinning
			Like pip freeze but pinning only packages that are in requirements.txt.
			This doesn't include any package that could be present in the virtualenv
			as result of manual installs or resolved dependencies.
	login
			Docker login
	build
			Build docker image
	tag
			Tag the latest Docker image into ECR.
	push
			Push the latest built Docker image into ECR.
	publish
			Publish a new Docker image into ECR. This target build, tag, and push a new image.
	run
			Run the latest image published into ECR.
	python-lint
			Run linting tools for python code in the ${UTILS_SRC} directory.
	lint
			Run linting tools for Python and Terraform code.

```

The application makes a query to the AWS  STS api to obtain the IAM user or role whose credentials are used to call the
operation.

```json
{
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/qweb-eks-node-group-20230627002412308100000001/i-0a8278645b0d9be8a",
    "ResponseMetadata": {
        "HTTPHeaders": {
            "content-length": "491",
            "content-type": "text/xml",
            "date": "Tue, 27 Jun 2023 01:31:47 GMT",
            "x-amzn-requestid": "b9c3537c-ca5a-4b6a-929f-e040d8e7cfea"
        },
        "HTTPStatusCode": 200,
        "RequestId": "b9c3537c-ca5a-4b6a-929f-e040d8e7cfea",
        "RetryAttempts": 0
    },
    "UserId": "ABCDEF12GHIJK3467AAAA:i-0a8278645b0d9be8a"
}
```

In addition to this, you can change the background color of the page by editing the `src/index.html` file. If the change
is pushed to the repository this would trigger a new image build and a subsequent deployment.


### Helm charts

For deployment the application into the kubernetes cluster we are using Helm charts. The idea is to declare the   
resources to be deployed using the best tool for that avoiding creating complex definition on terraform/hcl and 
allowing a better jobs division between different teams.

Helm charts for the qweb application are stored inside the directory `charts/qweb`.

### CI/CD

GitHub Actions are the solution used for the CI/CD process.
The workflows definition are stored in the `.github/worlflows`. All the workflows are configured with specific rules
based on git branch names and the project organization structure, and are triggerd based on pull request or direct push
to the master branch, and can also be manually triggerd by the GitHub Actions UI. The two *reclaim* workflows can only
be triggerd manually and requires a confirmation input by the user.
When the workflows are triggerd by a pull request, the result of each execution is posted as a comment in the pull
request including the build logs or the terraform plan depending on the case. In and GitHub Organization account the
branch protection rules can be configured to use the execution result to prevent the pull request to be merged.

There are four set of workflows, they are:
- Organization Infrastructure
- Project Infrastructure
- Kubernetes Resources
- Application Release


#### Organization Infrastructure

These workflow creates or reclaim organizational resources. e.g.: ECR repositories.

Workflows definitions:

 - *Organization Infrastructure Deployment* 
    [organization-infrastructure-deployment.yml](.github/workflows/organization-infrastructure-deployment.yml)

 - *Organization Infrastructure Reclaim/Destroy*
    [organization-infrastructure-destroy.yml](.github/workflows/organization-infrastructure-destroy.yml)


#### Project Infrastructure

These workflows create or reclaim the projects resources. e.g.: VPC, EKS Cluster, etc. 

Workflows definitions:

 - *Project Infrastructure Deployment* 
   [project-infrastructure-deployment.yml](.github/workflows/project-infrastructure-deployment.yml)
 
 - *Project Infrastructure Reclaim/Destroy* 
   [project-infrastructure-destroy.yml](.github/workflows/project-infrastructure-destroy.yml)


#### Kubernetes Resources

These workflows create or remove the kubernetes resources that are deployed into the EKS cluster.
Some of these resources are the Helm chart used to deploy the application. 

Workflows definitions:

 - *Kubernetes resources Deployment* 
   [project-infrastructure-deployment.yml](.github/workflows/project-infrastructure-deployment.yml)
 
 - *Kubernetes resources removal* 
   [project-infrastructure-destroy.yml](.github/workflows/project-infrastructure-destroy.yml)


#### Application release

This process build, tags and publish the image container to the AWS ECR repository.
The image is tagged using the tags:
 - `latest`
 - `<commit hash>` Using the first 8 characters to have a unique identifier of the image.
 - `<commit date>` Using the UTC date of commit, in the format `%Y%m%d.%H%M%S`

Workflows definitions:
 - *QWeb Application build and release* [applications-qweb.yml](.github/workflows/applications-qweb.yml)



### Workflow dependencies

Each time that there is a new application release the workflow `QWeb Application build and release` triggers the 
execution of the workflow "" 


### Secrets and variables

The following list of secrets and variables needs to be created via the GitHub UI.

#### Secrets

- `AWS_ACCESS_KEY_ID`: An AWS access key associated with an IAM account.
- `AWS_SECRET_ACCESS_KEY`: The secret key associated with the access key.

#### Variables

- `AWS_ACCOUNT_ID`: AWS account id.
- `AWS_DEFAULT_REGION`: The Default AWS Region to use.
- `ENV`: Environment or Stage. e.g.: `dev`, `stg`, `prd`.


## Handy commands

Obtain the application url: 
```shell
kubectl get ingress qweb \
  --template "http://{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"
```
example output
```shell
http://k8s-default-qweb-dad93923ee-32077523.eu-central-1.elb.amazonaws.com
```


Change the background color of the QWeb app to trigger a new deployment
```shell
export BG_COLOR="red" && \
      sed -i -E "s/(background-color:\ )(.*)/\1$BG_COLOR;/" applications/qweb/src/index.html && \
  grep background-color applications/qweb/src/index.html
```


Render Helm chart for debugging
```shell
helm template --debug charts/qweb > debug.yml
```


Run the application locally with docker
```shell
docker run -it --rm --name qweb -v ~/.aws:/root/.aws -p 127.0.0.1:8000:80 \
  <account_id>.dkr.ecr.<region>.amazonaws.com/qcase/qweb-dev:latest
```
access the application using the url `http://127.0.0.1:8000/`


Run the web application manually:
```shell
python applications/qweb/src/app.py
```

example output:
```shell
 * Serving Flask app 'qweb'
 * Debug mode: on
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8000
Press CTRL+C to quit
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 123-456-789
```



### Know issues.

- The `applications-qweb` workflow does not post the log into the pr.

- Terraform do not allways detect changes in the Helm charts, and for that reason the plan shows no changes.
  *Workaround:* publish a new image
  ```shell
   make -C applications/qweb/ publish
  ```
  

## TODO:

- Creating reusable workflows.
 - Merge resource creation workflows in a single Workflow to control the execution order.
 - Merge the Reclaim/Destroy workflows into a single one.


### Things than can be improved:

#### Terraform

- EKS resource tagging and mapping


#### Workflows:

- Investigate how to reuse a GitHub workflows definition to reduce the code duplication. And 
  See: https://docs.github.com/en/actions/using-workflows/reusing-workflows

#### At Bootstrap:

- Add a method to remove the s3 bucket when terraform resources are destroyed.
- Set this step as part of the CI/CD, to create these resources in the first run/commit.


## References:

Some documents used as references.

#### ALB docs:

- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

#### Ingress annotations

- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/guide/ingress/annotations/

#### Helm debugging.

- https://helm.sh/docs/chart_template_guide/debugging/
