# Terraform Azure Postgresql Server

Terraform module to create Azure Database for Postgresql Server.

## Usage

- See example to learn how to use this module

- Get certificate

```
curl -O --location https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem
```

- define connection settings

```
export SERVER_NAME=psql-server-name
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms | jq .accessToken | tr -d '"')
export USER_NAME=adm1n157r470r44D
```

- Database connection

```
psql "host=${SERVER_NAME}.postgres.database.azure.com \
        sslmode=verify-full \
        sslrootcert=BaltimoreCyberTrustRoot.crt.pem \
        user=${USER_NAME}@${SERVER_NAME} \
        dbname=postgres"
```

## To Do

What still needs to be done:

- [ ] Disable default admin generic account
- [ ] Allowing to configure SKU and pricing tier
- [ ] Allowing to create several databases
- [ ] Restrict network access
