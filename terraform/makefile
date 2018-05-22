# Terraform makefile by Rinat Abdullin 2018-05-22
BOLD=$(shell tput bold)
ERROR=$(shell tput setaf 1)
RESET=$(shell tput sgr0)

VARS=".secret.aws.tfvars"
CURRENT_FOLDER=$(shell basename "$$(pwd)")

help: ## Display help by printing target comments
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



set-env:
	@if [ ! -f "$(VARS)" ]; then \
		echo "$(BOLD)$(ERROR)Could not find variables file: $(VARS)$(RESET)"; \
		exit 1; \
	 fi

prep: set-env
	terraform init


plan: prep ## Show what terraform thinks it will do
	@terraform plan -var-file="$(VARS)" -lock=false -out my.plan

apply: plan ## Apply the changes
	@terraform apply "my.plan"

destroy: prep ## Destroy current setup
	@terraform destroy -var-file="$(VARS)" -lock=false
