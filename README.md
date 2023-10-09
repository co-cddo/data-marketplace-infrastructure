# Data-marketplace infrastructure


check the kubectl config  
check helm list -A  

check region setting

destroy:  
  remove EFS test
  remove ALB test
  remove persistence test
  remove ext.sec.



# Data-marketplace infrastructure

## This code is for Dev and Test Environments

Can be used to create dev and test infrasturcture which includes VPCs with subnets, EKS clusters, ALBs, EFS, Parameter Store with secrets and external secrets.

### Pre-requisites:

* Install git: https://linux.how2shout.com/how-to-install-git-on-aws-ec2-amazon-linux-2/
* Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
* Install awscli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
  
### For Environment Creation:

Run `cd dev` or `cd test`
Run `terraform init`
Run `terraform plan` and check the output.
If the output is what you expect and there are no errors:
Run `terraform apply`

To start the ALB, go to the app folder and create deployments and services for frontend, frontend-ingress, frontend-ingress-secure, backend-api  and fuseki by running:

`kubectl apply -f <filename.yml>`

for each file.


### Destroy Resources:

If you want to destroy the dev environment:

* First, remove the ALB and Target Groups manually from the AWS Portal:

* `cd dev` or `cd test`, then run `terraform destroy`


### References:

* For the VPC, subnets, IGW, NAT, EKS, EFS, ALB: https://antonputra.com/amazon/create-aws-eks-fargate-using-terraform/#deploy-aws-load-balancer-controller-using-terraform

* For External Secrets: https://alto9.com/2021/07/05/using-aws-secrets-manager-with-eks-and-terraform/ and https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/
  
* For Parameter Store: https://devpress.csdn.net/cicd/62ec66e689d9027116a10dbd.html and https://github.com/unfor19/terraform-aws-ssm-parameters/blob/master/main.tf
  


