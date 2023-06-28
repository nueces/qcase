# Infrastructure

Inside this directory are two subdirectories that contains terraform files needed to build the infrastructure and deploy the application.

#### subdirectories:

- main-resources: Contains the VPC, EKS Cluster, and in general should contain the definition for any other AWS resource.
- kubernetes-resources: Contains the Kubernetes resources, that are provisioned in the EKS cluster, and any other AWS 
  resources needed for that, like IAM roles, etc.


#### Why?

During the installation of the AWS lb controller, if faced some of the following issues, and after exploring some 
options I decided to refactor the previous approach of a single project infrastructure folder into the current solution.

Issues

- In some circumstances terraform kubernetes provider fails to be set.
  See: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources

  *Workaround:* create a kubeconfig file and export the environment variable pointing to it.
  ```shell
  make kubeconfig
  export KUBE_CONFIG_PATH=$(realpath kubeconfig)
  ```
  Even when this workaround could work in some situations, it does not in the initial setup, where the cluster does not
  exist and because of that is impossible to have the kubectl configuration file.

The recommended approach for solve this issue is to manage terraform definition for the EKS cluster and kubernetes
resources in two different stacks, as is pointed in the previous documentation link.
See: https://github.com/hashicorp/terraform-provider-kubernetes/blob/main/_examples/eks/README.md



### Terraform

In both subdirectories there is a Makefile that contains a set of specific targets to use during the development or deployment phase.

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
