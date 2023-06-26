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

# Configurations
PROJECT_CONFIGURATION = ../../configuration.yml
APP_SRC = src


# Packages installed in the virtualenv place their commands in the bin directory inside virtualenv path.
# So we are going to prefix all commands with virtualenv bin path.
VENV_PATH = ../../venv
# python commands
PYTHON   = ${VENV_PATH}/bin/python3
PIP      = ${VENV_PATH}/bin/pip
BLACK    = ${VENV_PATH}/bin/black
ISORT    = ${VENV_PATH}/bin/isort
PYLINT   = ${VENV_PATH}/bin/pylint
YQ       = ${VENV_PATH}/bin/yq


ifndef AWS_DEFAULT_REGION
	AWS_DEFAULT_REGION = $(shell ${YQ} < ${PROJECT_CONFIGURATION} -r .aws_region)
endif

ifndef ECR_REGISTRY
	ACCOUNT_ID   = $(shell aws sts get-caller-identity --output text --query Account)
	ECR_REGISTRY = ${ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
endif

ifndef ENV
	ENV = dev
endif

PROJECT_NAME   = $(shell ${YQ} < ${PROJECT_CONFIGURATION} -r .project_name)
APP_NAME       = $(shell basename $(CURDIR))
REVISION       = $(shell git rev-parse HEAD | cut -c1-8)
DATE_STAMP     = $(shell TZ=UTC git show -s --date=format:'%Y%m%d.%H%M%S' --format=%cd ${REVISION})  # Use commit date


IMAGE_NAME = ${PROJECT_NAME}/${APP_NAME}-${ENV}

#############################################################################

.PHONY: debug
debug: ##@ Used for development.
	aws ecr describe-repositories --repository-names ${PROJECT_NAME}/${APP_NAME}-${ENV}
	$(info ${PROJECT_NAME})
	$(info ${AWS_DEFAULT_REGION})
	$(info ${ECR_REGISTRY})
	$(info ${APP_NAME})
	$(info ${DATE_STAMP})
	$(info ${REVISION})
	$(info ${IMAGE_NAME})


.PHONY: help
help: ##@ Show this help.
	@$(usage)


.PHONY: pip-pinning
pip-pinning: ##@ Like pip freeze but pinning only packages that are in requirements.txt.
##@		This doesn't include any package that could be present in the virtualenv
##@		as result of manual installs or resolved dependencies.
	REQ="$(shell ${PIP} freeze --quiet --requirement requirements.txt | sed '/^## The following requirements were added by pip freeze:$$/,$$ d')";\
	echo $$REQ | sed 's/ /\n/g' > requirements.txt


.PHONY: login
login: ##@ Docker login
	aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}


.PHONY: build
build: ##@ Build docker image
	docker build --no-cache -t ${IMAGE_NAME} .


.PHONY: tag
tag: ##@ Tag the latest Docker image into ECR.
	docker tag ${IMAGE_NAME}:latest ${ECR_REGISTRY}/${IMAGE_NAME}:latest
	docker tag ${IMAGE_NAME}:latest ${ECR_REGISTRY}/${IMAGE_NAME}:${REVISION}
	docker tag ${IMAGE_NAME}:latest ${ECR_REGISTRY}/${IMAGE_NAME}:${DATE_STAMP}


.PHONY: push
push: ##@ Push the latest built Docker image into ECR.
	docker push ${ECR_REGISTRY}/${IMAGE_NAME}:latest
	docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${REVISION}
	docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${DATE_STAMP}


.PHONY: publish
publish: login build tag push ##@ Publish a new Docker image into ECR. This target build, tag, and push a new image.
	$(info Image published!)
	$(info You can run the ${APP_NAME} image running the following command)
	$(info docker run -it --rm --name ${APP_NAME} -v ~/.aws:/root/.aws -p 8080:80 ${ECR_REGISTRY}/${IMAGE_NAME}:latest)
	$(info or executing `make run`)

.PHONY: run
run: ##@ Run the latest image published into ECR.
	$(info running the latest image published into ECR)
	docker run -it --rm --name ${APP_NAME} -v ~/.aws:/root/.aws -p 8080:80 ${ECR_REGISTRY}/${IMAGE_NAME}:latest

.PHONY: python-lint
python-lint: ##@ Run linting tools for python code in the ${UTILS_SRC} directory.
	$(info Running Python linting tools.)
	${BLACK} ${APP_SRC}
	${ISORT} ${APP_SRC}
	${PYLINT} ${APP_SRC}


.PHONY: lint
lint: python-lint ##@ Run linting tools for Python and Terraform code.
	$(info Lint done!)
