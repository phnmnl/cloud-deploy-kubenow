#!/usr/bin/env bash
set -e

# provider specific
export PROVIDER="byoc"

"$PORTAL_APP_REPO_FOLDER/cloud_portal/shared/deploy.sh"
