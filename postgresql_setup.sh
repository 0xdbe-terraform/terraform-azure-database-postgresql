
# Get token for Postgresql
export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms | jq .accessToken | tr -d '\"')

# Run sql command
psql "host=${SERVER_NAME}.postgres.database.azure.com \
  sslmode=verify-full \
  sslrootcert=BaltimoreCyberTrustRoot.crt.pem \
  user=${USER_NAME}@${SERVER_NAME} \
  dbname=postgres" \
  --set=group="${GROUP_NAME}" \
  -f postgresql_setup.sql