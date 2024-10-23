# Data-marketplace infrastructure

This changed code can be used to create infrasturcture which includes for services of data marketplace.

### Pre-requisites:

* Install git: https://linux.how2shout.com/how-to-install-git-on-aws-ec2-amazon-linux-2/
* Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli (Required version - Terraform v1.5.7)
* Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
* Install awscli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
* Cognito user pool and client app
* a domain name and tls certificate for the domainname.
* SSO settings on the security.gov.uk

### Local development

Use assume role access to run terraform plan locally.

* Require AWS user account with assume role (ROLE_ARN=arn:aws:iam::855859226163:role/dm-gen-devops-role) access
* Create sts session keys

      export ROLE_ARN="arn:aws:iam::855859226163:role/dm-gen-devops-role"
      export MFA_DEVICE_ARN="arn:aws:iam::855859226163:mfa/<MFANAME>"

      aws sts assume-role \
        --role-arn "$ROLE_ARN" \
        --serial-number "$MFA_DEVICE_ARN" \
        --token-code "<MFA_CODE>" \
        --role-session-name "terraform-session"

      export AWS_PROFILE=terraform-session

Alternately, the jump host (adm-instance) on AWS account can be used for deployment as well.

### For Environment Creation:
There are multiple environments: dev, tst, mvp. One can create any other environment by copying one of them and updating the variables section (for example, CIDR, env name, etc). Below process is for dev envrionment creation. By replacing the dev to other environment, one can create the other environment as well
* Run `cd dev`
* Run `terraform init`
* Run `terraform plan` and check the output.
If the output is what you expect and there are no errors:
* Run `terraform apply`

    If CoreDNS patch failed for due to some error then run `terraform apply` again and then `kubectl rollout restart -n kube-system deployment coredns`

* For SSO, define client settings on security.gov.uk (for first time, only once!)
* For restricted access to the env, create cognito user pool and define app client in the userpool
* Go to Paramater Store in AWS Systems Manager portal and fill in the values for the parameters for /dm/dev/*.
* Generate ACM for the required domain (To be automated)
* `cd app`.
* Create .env file with parameters (dev.env file is a template file for .env)
* Then run `sh dm-deploy.sh install`.
* define a custom DNS record (CNAME) for Application Load Balancer DNS
* Update the EFS backup for the newly create environment. 

### Destroy Resources:

If you want to destroy the dev environment:

* Run `sh dm-deploy.sh uninstall` from the app folder.
* `cd dev` , then run `terraform destroy`
* remove kubernetes config for the environment.

MVP & TST environments destroyed as new test environments created by AGM in Azure Cloud.

### Update the services 
* `cd app`.
* Create .env file with parameters (dev.env file is a template file for .env)
* Then run `sh dm-deploy.sh update`.  
  
### Backup and Restore 

Backend database fuseki using EFS as persistence and its protected by AWS backup service.
Backup restore can be done manually in the event of any data loss using AWS backup restore feature.

### Add IAM users to aws_auth config if required
kubectl edit configmap aws-auth -n kube-system

    mapUsers: |
        - userarn: arn:aws:iam::<AWS_ACCOUNT_ID>:user/<USERNAME>
          username: admin
          groups:
            - system:masters

### Additional improvements notes

CoreDNS plugin resources created for MVP environment to avoid applying DNS patching. Dev environment is still using CoreDNS patching which is controlled through terraform variable.

### TODO by Code
* Generate certificate the new test domain
* Add DNS record for the new environment
* CI/CD for IaC & app deployment
* Import AWS backup resource creation in IaC
