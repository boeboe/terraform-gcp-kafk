# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
.PHONY: init build validate

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


init: ## Initialize packer
	packer init config.pkr.json

build: ## Build packer images
	packer build -force grafana-image.json
	packer build -force influxdb-image.json
	packer build -force kafka-image.json
	packer build -force zookeeper-image.json

validate: init ## Validate packer syntax and linting
	packer validate .
	packer fmt -recursive .
