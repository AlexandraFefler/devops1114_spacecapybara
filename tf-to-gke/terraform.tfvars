# project_id = "lateral-insight-471417-u9"
# # originally zone was b
# zone = "us-central1-a" #in Github vaariables it's c not a 
# region = "us-central1"

# learned that terraform searches for vars first in here (terraform.tfvars), then for TF_VAR_* vars in the larger environment scope 
# (in this case, the larger env scope is the github actions runner vm, running the terraform apply command. those TF_VARs are in ci_cd.yaml)