# Terraform Azure Database for Postgresql

Terraform module to create Azure Database for Postgresql Server.

## Access control

This module create two groups to manage access control to Postgresql Server:

- A group for administrators
- A group for users

Administrators and Users must be user principals (or, maybe, Managed Idenities).

## Deploy database

Prerequisite:

- A ressource groupe
- At least, one user principal who will be database admistrator
- At least, one user principal who will be database user

This ressource can be created using terraform, az cli or azure portal.

Then, Postgresql can be created using this module as shown in the example.
A service principal with enough rights (on AzureAD and AzureRM) must be used to deploy.


## Database connection as Administrator


- Authentication with the appropriate user principal

```
az login
```

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

```
postgres=> \conninfo

You are connected to database "postgres" as user "adm1n157r470r44D@psql-server-hw-dev-XYZ" on host "psql-server-hw-dev-XYZ.postgres.database.azure.com" (address "40.71.8.203") at port "5432".
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
```

## Database connection as User

- Authentication with the appropriate user principal

```
az login
```

- Get certificate

```
curl -O --location https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem
```

- define connection settings

```
export SERVER_NAME=psql-server-hw-dev-XYZ
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms | jq .accessToken | tr -d '"')
export USER_NAME=group-hw-dev-psql-users
```

- Database connection

```
psql "host=${SERVER_NAME}.postgres.database.azure.com \
        sslmode=verify-full \
        sslrootcert=BaltimoreCyberTrustRoot.crt.pem \
        user=${USER_NAME}@${SERVER_NAME} \
        dbname=appdb"
```

```
appdb=> \conninfo

You are connected to database "appdb" as user "group-hw-dev-psql-users@psql-server-hw-dev-XYZ" on host "psql-server-hw-dev-XYZ.postgres.database.azure.com" (address "40.71.8.203") at port "5432".
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
```

- If error, verify that access token includes the new group

```
psql: error: could not connect to server: FATAL:  Azure AD access token not valid for role group-hw-dev-psql-user (does not contain group ID ba0ea787-9e71-4e9e-834d-71aa7f32361b)
HINT:  Did you specify the correct user name and access token?
```

```
jq -R 'split(".") | .[1] | @base64d | fromjson' <<< "$PGPASSWORD"
```

## To Do

What still needs to be done:

- [ ] Disable default admin generic account
- [ ] Allowing to configure SKU and pricing tier
- [ ] Restrict network access
- [ ] Grant access on databases
