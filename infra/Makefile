SHELL   := /usr/bin/env bash
NIXOPS  := $(shell which nixops)
DEPLOYMENT_NAME := buildit-ops

.create:
	$(NIXOPS) list | grep "$(DEPLOYMENT_NAME)" || \
		$(NIXOPS) create configuration.nix hardware.nix -d $(DEPLOYMENT_NAME)

deploy: .create
	$(NIXOPS) deploy -d $(DEPLOYMENT_NAME) --kill-obsolete --allow-reboot

ssh:
	$(NIXOPS) ssh -d $(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)