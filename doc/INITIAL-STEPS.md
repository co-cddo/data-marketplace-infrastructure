# How To Use This Repo
For initial install, e.g. creating a new environment, you need to change directory to one of pre-configured folders
- dev (Development Environment)
- tst (Test Environment)
- stg (Stage Environment)
- pro (Production Environment)

Then run in order  
`terraform init`  
`terraform plan`  
`terraform apply`

When you run Terraform init and plan you need to supply some variables e.g.

```
tf plan \
-var    rds_mssql_snapshot_identifier="arn:aws:rds:eu-xxxx-x:xxxxxxxxxxxx:snapshot:dm-mssql-sample-base-initial" \
-var rds_postgres_snapshot_identifier="arn:aws:rds:eu-xxxx-x:xxxxxxxxxxxx:snapshot:dm-postgres-sample-base-initial"
```

For the application installs a skeleton entry will be created by Terraform initial run at AWS Parameter Store in a name of
`/dm/dev/config-inputs-json`

```bash
export DOMAIN_NAME=""
export SSO_CLIENT_ID=""
export SSO_CLIENT_SECRET=""
export MS_DBSERVER=""
export MS_PORT=""
export MS_DATABASE_SHARE=""
export MS_DATABASE_USERS=""
export MS_TRUSTSVRCERT=""
export PG_DBSERVER=""
export PG_PORT=""
export PG_DATABASE=""
export PG_USERID=""
export PG_PW=""
export MS_USERID=""
export MS_PW=""

# OPTIONAL (FOR NOW)
export SECRETKEY=""
export AUDIENCES=""
export GOV_NOTIFY_API_KEY=""
export NEW_DATA_SHARE_REQUEST_RECEIVED_TEMPLATE_ID=""
export DATA_SHARE_REQUEST_CANCELLED_TEMPLATE_ID=""
export DATA_SHARE_REQUEST_ACCEPTED_TEMPLATE_ID=""
export DATA_SHARE_REQUEST_REJECTED_TEMPLATE_ID=""
export DATA_SHARE_REQUEST_RETURNED_WITH_COMMENTS_TEMPLATE_ID=""
export WELCOMETEMPLATE=""
export PG_DATABASE_URL=""
export GOOGLE_CLIENT_ID=""
export GOOGLE_CLIENT_SECRET=""
export RACK_ENV=""
export RAILS_ENV=""
export SECRET_KEY_BASE=""
```
Then you need to populate with actual values. Please attention that thpse variables are above in a "Encrypted" format and you need either AWS console or AWS CLI with a right permisions to edit / modify it.  
Once edited and populated with values you need to run  
```
# cd root of the repo first
# then
cd app-fast/config/
./create.sh [env]
# For example
./create.sh dev
```

That will create 5 application configuration entries in AWS Parameter Store as

- /dm/[env]/appsettings/api
- /dm/[env]/appsettings/catalogue
- /dm/[env]/appsettings/datashare
- /dm/[env]/appsettings/ui
- /dm/[env]/appsettings/users

e.g.

```
/dm/dev/appsettings/api
/dm/dev/appsettings/catalogue
/dm/dev/appsettings/datashare
/dm/dev/appsettings/ui
/dm/dev/appsettings/users
```

That will enable you to run the application installed by `app-fast` folder.

