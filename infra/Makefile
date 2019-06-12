# move this make scripts to shell.nix
SHELL   := /usr/bin/env bash
NIXOPS  := $(shell which ops)
DEPLOYMENT_NAME := buildit-ops

# local env
.create-local:
	$(NIXOPS) list | grep "$(DEPLOYMENT_NAME)-local" || \
		$(NIXOPS) create configuration.nix virtualbox.nix -d $(DEPLOYMENT_NAME)-local

deploy-local: .create-local
	$(NIXOPS) deploy -d $(DEPLOYMENT_NAME)-local --kill-obsolete --allow-reboot

destroy-local:
	$(NIXOPS) destroy -d $(DEPLOYMENT_NAME)-local

ssh-local:
	$(NIXOPS) ssh -d $(DEPLOYMENT_NAME)-local $(DEPLOYMENT_NAME)

# ec2
.create-ec2:
	$(NIXOPS) list | grep "$(DEPLOYMENT_NAME)-ec2" || \
		$(NIXOPS) create configuration.nix ec2.nix -d $(DEPLOYMENT_NAME)-ec2

deploy-ec2: .create-ec2
	# $(NIXOPS) deploy -d $(DEPLOYMENT_NAME)-ec2 --kill-obsolete --allow-reboot --allow-recreate

destroy-ec2:
	# $(NIXOPS) destroy -d $(DEPLOYMENT_NAME)-ec2

ssh-ec2:
	# $(NIXOPS) ssh -d $(DEPLOYMENT_NAME)-ec2 $(DEPLOYMENT_NAME)