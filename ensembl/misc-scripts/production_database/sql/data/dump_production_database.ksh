#!/bin/ksh

dbhost="ens-staging1"
dbuser="ensro"

# The only thing not properly dumped by the following command are the
# views, but that's of minor importance as the view definitions are
# available in the table.sql file.

mysqldump --skip-opt --skip-compact --order-by-primary \
  --force --host="${dbhost}" --user="${dbuser}" --password="${dbpass}" \
    ensembl_production > ensembl_production.dump 2>/dev/null
