# Data-marketplace infrastructure

This code can be used to create infrasturcture which includes for services of data marketplace.

### Pre-requisites:

* Install git: https://linux.how2shout.com/how-to-install-git-on-aws-ec2-amazon-linux-2/
* Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
* Install awscli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
  
### For Environment Creation:
There are multiple environments: dev, tst, mvp. One can create any other environment by copying one of them and updating the variables section (for example, CIDR, env name, etc). Below process is for dev envrionment creation. By replacing the dev to other environment, one can create the other environment as well
* Run `cd dev`
* Run `terraform init`
* Run `terraform plan` and check the output.
If the output is what you expect and there are no errors:
* Run `terraform apply`
* Go to Paramater Store in AWS Systems Manager portal and fill in the values for the parameters for /dm/dev/*.
* `cd app`.
* Create .env file with parameters (dev.env file is a template file for .env)
* Then run `sh dm-deploy.sh install`.

### Destroy Resources:

If you want to destroy the dev environment:

* Run `sh dm-deploy.sh uninstall` from the app folder.
* `cd dev` , then run `terraform destroy`
* remove kubernetes config for the environment.

### Update the services 
* `cd app`.
* Create .env file with parameters (dev.env file is a template file for .env)
* Then run `sh dm-deploy.sh update`.
