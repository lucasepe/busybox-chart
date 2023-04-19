# Set the shell to bash always
SHELL := /bin/bash

# Look for a .env file, and if present, set make variables from it.
ifneq (,$(wildcard ./.env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif

KIND_CLUSTER_NAME ?= local-dev
KUBECONFIG ?= $(HOME)/.kube/config
RELEASE_NAME := $(shell awk -v key='name' -F ':' '$$1==key{print $$2}' chart/Chart.yaml)


# Tools
KIND=$(shell which kind)
KUBECTL=$(shell which kubectl)
HELM=$(shell which helm)


.DEFAULT_GOAL := help

.PHONY: kind-up
kind-up: ## starts a KinD cluster for local development
	@$(KIND) get kubeconfig --name $(KIND_CLUSTER_NAME) >/dev/null 2>&1 || $(KIND) create cluster --name=$(KIND_CLUSTER_NAME)

.PHONY: kind-down
kind-down: ## shuts down the KinD cluster
	@$(KIND) delete cluster --name=$(KIND_CLUSTER_NAME)

.PHONY: clean
clean:
	@rm $(RELEASE_NAME)-*.tgz || true

.PHONY: render
render: ## locally render the chart template
	@$(HELM) template $(RELEASE_NAME) ./chart 

.PHONY: package
package: clean ## package the chart 
	@$(HELM) package ./chart

.PHONY: install
install: ## install this chart
	@$(HELM) upgrade -i $(RELEASE_NAME) ./chart --namespace demo-system --create-namespace

.PHONY: uninstall
uninstall: ## uninstall this chart
	@$(HELM) uninstall $(RELEASE_NAME) --namespace demo-system

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ./Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'