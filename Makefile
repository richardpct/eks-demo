.DEFAULT_GOAL   := help
AWK             := awk
EKSCTL          := eksctl
CLUSTER_NAME    := demo
K8S_VERS        := 1.14
NODE_GROUP_NAME := standard-workers
EC2_TYPE        := t2.micro
NODE_NB         := 2
NODE_MIN        := 1
NODE_MAX        := 2
NODE_AMI        := auto
AWS_REGION      := eu-west-3

.PHONY: help
help: ## Show help
	@echo "Usage: make TARGET\n"
	@echo "Targets:"
	@$(AWK) -F ":.* ##" '/^[^#].*:.*##/{printf "%-9s%s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) \
	| grep -v AWK

build: ## Build the Kubernetes cluster on AWS
	$(EKSCTL) create cluster \
	--name $(CLUSTER_NAME) \
	--version $(K8S_VERS) \
	--nodegroup-name $(NODE_GROUP_NAME) \
	--node-type $(EC2_TYPE) \
	--nodes $(NODE_NB) \
	--nodes-min $(NODE_MIN) \
	--nodes-max $(NODE_MAX) \
	--node-ami $(NODE_AMI)

	@touch $@

.PHONY: destroy
destroy: ## Destroy the kubernetes cluster
	if [ -f build ]; then \
	  $(EKSCTL) delete cluster --region=$(AWS_REGION) --name $(CLUSTER_NAME); \
	fi

	@rm build
