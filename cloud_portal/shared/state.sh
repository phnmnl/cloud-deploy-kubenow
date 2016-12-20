#!/usr/bin/env bash

# Query Terraform state file
terraform show $PORTAL_DEPLOYMENTS_ROOT'/'$PORTAL_DEPLOYMENT_REFERENCE'/terraform.tfstate'
