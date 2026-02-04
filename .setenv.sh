#!/usr/bin/env bash
# 1. Load static values into the current shell
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    echo "Static variables loaded from .env"
fi


# Vault server address
export VAULT_ADDR="https://knox.io.nrs.gov.bc.ca"

# Login locally (interactive or pre-configured OIDC)
export VAULT_TOKEN=$(vault login -method=oidc -tls-skip-verify -format=json | jq -r '.auth.client_token')
export API_TOKEN=$(vault kv get -field=API_TOKEN "apps/dev/oscar-example/nodejs-sample/development")
