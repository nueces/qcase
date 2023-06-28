# Makefile
.DEFAULT_GOAL:=help

define usage
	# The sed command use the {#}\2 to avoid using two consecutive #
	@echo "\nUsage: make <target> "\
		 "[one or more targets separated by spaces and in the order that their would executed]\n\n"\
		 "The following targets are available: \n"
	@sed -e '/#\{2\}@/!d; s/\\$$//; s/:[^#\t]*/\n\t\t\t/; s/^/\t/; s/#\{2\}@ *//' $(MAKEFILE_LIST)
	@echo "\n"
endef

PROJECT_CONFIGURATION = ../../configuration.yml

ifdef targets
options := $(foreach target,$(targets),-target $(target))
endif

ifndef AWS_DEFAULT_REGION
	AWS_DEFAULT_REGION = $(shell sed -n -E "s/[[:space:]]*(aws_region\:)[[:space:]]*(.*)/\2/1p" < ${PROJECT_CONFIGURATION})
endif

AWS_ACCOUNT_ID  = $(shell aws sts get-caller-identity --query Account --output text)
STACK_NAME      = $(shell basename $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
SUFFIX_NAME     = $(shell sed -n -E "s/[[:space:]]*(bucket_suffix_name\:)[[:space:]]*(.*)/\2/1p" < ${PROJECT_CONFIGURATION})

TF_BUCKET = ${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-${SUFFIX_NAME}
TF_KEY    = ${STACK_NAME}.tfstate


.PHONY: help
help: ##@ Show this help.
	@$(usage)


.PHONY: init
init: ##@ Run terraform init.
	terraform --version
	terraform init \
		-backend-config="bucket=${TF_BUCKET}" \
		-backend-config="key=${TF_KEY}" \
		-backend-config="region=${AWS_DEFAULT_REGION}"

.PHONY: reconfigure
reconfigure: ##@ Run terraform init --reconfigure.
	terraform --version
	terraform init --reconfigure\
		-backend-config="bucket=${TF_BUCKET}" \
		-backend-config="key=${TF_KEY}" \
		-backend-config="region=${AWS_DEFAULT_REGION}"


.PHONY: plan
plan: fmt ##@ Run terraform format, and terraform plan storing the plan for the apply phase.
	terraform plan --out=plan.out -no-color $(options) | tee plan.log


.PHONY: plan-destroy
plan-destroy: ##@ Run terraform plan -destroy storing the plan for the apply phase.
##@		A TARGETS variable containing a space separated list of resources can by provided
##@		to processed and used as targets with -target.
	terraform plan -destroy $(options) --out=plan.out -no-color | tee plan.log


.PHONY: apply
apply: ##@ Runs terraform apply with a previous created plan.
	terraform apply plan.out


.PHONY: deploy
deploy: ##@ Runs the init, plan, and apply targets.
	$(info "Running init plan apply")
	@$(MAKE) init plan apply


.PHONY: destroy
destroy: ##@ Runs terraform destroy.
	$(info "Kaboom")
	terraform destroy


# Helpers
.PHONY: fmt
fmt: ##@ Runs terraform format updating the needed files.
	terraform fmt -diff -recursive


.PHONY: validate
validate: fmt ##@ Runs fmt target and terraform validate.
	terraform validate


.PHONY: clean
clean: ##@ Clean saved plans and logs.
	rm -f plan.out plan.log;
