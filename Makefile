.DEFAULT_GOAL   := help
AWK             := awk
CURL            := curl
TAR             := tar
JQ              := jq
KUBECTL         := kubectl
EKSCTL          := eksctl
BUILD           := .build
METRICS         := .metrics
CLUSTER_NAME    := demo
K8S_VERS        := 1.14
NODE_GROUP_NAME := standard-workers
EC2_TYPE        := t2.micro
NODE_NB         := 2
NODE_MIN        := 1
NODE_MAX        := 2
NODE_AMI        := auto
AWS_REGION      := eu-west-3
TMP             := /tmp

.PHONY: help
help: ## Show help
	@echo "Usage: make TARGET\n"
	@echo "Targets:"
	@$(AWK) -F ":.* ##" '/^[^#].*:.*##/{printf "%-9s%s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) \
	| grep -v AWK

.PHONY: build
build: $(BUILD) ## Build the Kubernetes cluster on AWS


$(BUILD):
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
	if [ -f $(BUILD) ]; then \
	  $(EKSCTL) delete cluster --region=$(AWS_REGION) --name $(CLUSTER_NAME); \
	fi

	@rm -fv $(BUILD)
	@rm -fv $(METRICS)

.PHONY: metrics
metrics: $(METRICS) ## Install metric server

$(METRICS): DOWNLOAD_URL = $(shell $(CURL) --silent "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | $(JQ) -r .tarball_url)
$(METRICS): DOWNLOAD_VERSION=$(shell grep -o '[^/v]*$$' <<< $(DOWNLOAD_URL))
$(METRICS): $(BUILD)
	$(CURL) -Ls $(DOWNLOAD_URL) -o $(TMP)/metrics-server-$(DOWNLOAD_VERSION).tar.gz
	mkdir $(TMP)/metrics-server-$(DOWNLOAD_VERSION)
	$(TAR) -xzf $(TMP)/metrics-server-$(DOWNLOAD_VERSION).tar.gz --directory $(TMP)/metrics-server-$(DOWNLOAD_VERSION) --strip-components 1
	$(KUBECTL) apply -f $(TMP)/metrics-server-$(DOWNLOAD_VERSION)/deploy/1.8+/
	@touch $@
