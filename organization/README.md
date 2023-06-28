# Organization Infrastructure

This directory contains terraform resources that are typically built as pre-requisite for a specific project.
In a real-life scenario these resources are managed in a separated repository.


## Resources:

### ECR
The registry needs to be built before the of the initial image build, process that is not managed by terraform.


### Terraform

There is a Makefile that contains a set of specific targets to use during the development or deployment phase.

```shell
make

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
