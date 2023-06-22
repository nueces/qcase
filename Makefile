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
UTILS=utils
INFRASTRUCTURE=infrastructure
PROJECT_CONFIGURATION=configuration.yml

# Packages installed in the virtualenv place their commands in the bin directory inside virtualenv path.
# So we are going to prefix all commands with virtualenv bin path.
VENV_PATH = venv
# python commands
PYTHON = ${VENV_PATH}/bin/python3
PIP    = ${VENV_PATH}/bin/pip
BLACK  = ${VENV_PATH}/bin/black
ISORT  = ${VENV_PATH}/bin/isort
PYLINT = ${VENV_PATH}/bin/pylint

#############################################################################

.PHONY: help
help: ##@ Show this help.
	@$(usage)

.PHONY: bootstrap
bootstrap: ##@ Create the virtualenv to run pip-install target.
	rm -rf ${VENV_PATH}
	python3 -m venv ${VENV_PATH}
	# Install python dependencies
	@$(MAKE) pip-install
	${PYTHON} utils/bootstrap.py --configuration $(PROJECT_CONFIGURATION)


.PHONY: pip-install
pip-install: ##@ Install python dependencies using pip.
	${PIP} install --requirement requirements.txt


.PHONY: pip-upgrade
pip-upgrade: ##@ Upgrade python dependencies using pip. This ignore pinning versions in requirements.txt.
##@		But only updates packages that are in that file.
	${PIP} install --upgrade $(shell sed -e '/^[a-zA-Z0-9\._-]/!d; s/=.*$$//' requirements.txt)


.PHONY: pip-pinning
pip-pinning: ##@ Like pip freeze but pinning only packages that are in requirements.txt.
##@		This doesn't include any package that could be present in the virtualenv
##@		as result of manual installs or resolved dependencies.
	REQ="$(shell ${PIP} freeze --quiet --requirement requirements.txt | sed '/^## The following requirements were added by pip freeze:$$/,$$ d')";\
	echo $$REQ | sed 's/ /\n/g' > requirements.txt


.PHONY: pip-uninstall
pip-uninstall: ##@ Uninstall python dependencies using pip.
	${PIP}  pip uninstall --yes --requirement requirements.txt


.PHONY: deploy
deploy: ##@ Deploy infrastructure running terraform.
	$(info >>> For more specific terraform related targets. Execute `make help` in the ${INFRASTRUCTURE} directory)
	make -C ${INFRASTRUCTURE} deploy

.PHONY: destroy
destroy: ##@ Destroy infrastructure running terraform.
	$(info >>> For more specific terraform related targets. Execute `make help` in the ${INFRASTRUCTURE} directory)
	make -C ${INFRASTRUCTURE} destroy

.PHONY: python-lint
python-lint: ##@ Run linting tools for python code in the ${UTILS_SRC} directory.
	$(info Running Python linting tools.)
	${BLACK} ${UTILS}
	${ISORT} ${UTILS}
	${PYLINT} ${UTILS}

.PHONY: terraform-lint
terraform-lint: ##@Run linting tools for terraform code in the ${INFRASTRUCTURE} directory.
	$(info Running Terraform linting tools.)
	make -C ${INFRASTRUCTURE} fmt validate

.PHONY: lint
lint: python-lint terraform-lint ##@ Run linting tools for Python and Terraform code.
	$(info Lint done!)
