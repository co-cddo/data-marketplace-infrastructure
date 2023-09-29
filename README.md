# Data-marketplace infrastructure

## This code is for Dev and Test Environments

Can be used to create dev and test infrasturcture which includes VPCs with subnets, EKS clusters, ALBs, EFS, Parameter Store with secrets and external secrets.

### For Dev Environment:

Run `cd dev`
Run `terraform init`
Run `terraform plan` and check the output.
If the output is what you expect and there are no errors:
Run `terraform apply`

At the end, you would need to update your Kubernetes context to access the cluster with the following command:

`aws eks update-kubeconfig --name dm-eks-dev --region eu-north-1`

The name for the cluster and the region in the Terraform variables.tf file in the dev folder.

To start the ALB, go to the app folder and create deployments and services for frontend, frontend-ingress, frontend-ingress-secure, backend-api  and fuseki by running:

`kubectl apply -f <filename.yml>`

for each file.



### For Test Environment:

Run `cd test`
Run `terraform init`
Run `terraform plan` and check the output.
If the output is what you expect and there are no errors:
Run `terraform apply`

At the end, you would need to update your Kubernetes context to access the cluster with the following command:

`aws eks update-kubeconfig --name dm-eks-test --region eu-north-1`

The name for the cluster and the region in the Terraform variables.tf file in the test folder.
To start the ALB, go to the app folder and create deployments and services for frontend, frontend-ingress, frontend-ingress-secure, backend-api  and fuseki by running:

`kubectl apply -f <filename.yml>`

for each file.

### Errors:

If you see the following errors: 

* `Kubernetes cluster unreachable: invalid configuration: no configuration has been provided, try setting KUBERNETES_MASTER environment variable`

run the following command:

`export KUBE_CONFIG_PATH=/home/ec2-user/.kube/config`

*  For the following error:

<img width="1239" alt="Screenshot 2023-09-29 at 12 38 24" src="https://github.com/co-cddo/data-marketplace-infrastructure/assets/117096090/c7467e30-6dde-4597-814d-4f056a56fc22">

run `aws eks update-kubeconfig --name dm-eks-test --region eu-north-1`

* “Fixing ‘Cannot Re-Use a Name That Is Still In Use’ Error in Terraform Helm Kubernetes Deployments”: https://maripeddi-supraj.medium.com/fixing-cannot-re-use-a-name-that-is-still-in-use-error-in-terraform-helm-kubernetes-deployments-5c86afa3e8f9

### References:

* For the VPC, subnets, IGW, NAT, EKS, EFS, ALB: https://antonputra.com/amazon/create-aws-eks-fargate-using-terraform/#deploy-aws-load-balancer-controller-using-terraform

* For External Secrets: https://alto9.com/2021/07/05/using-aws-secrets-manager-with-eks-and-terraform/ and https://aws.amazon.com/blogs/containers/leverage-aws-secrets-stores-from-eks-fargate-with-external-secrets-operator/
  
* For Parameter Store: https://devpress.csdn.net/cicd/62ec66e689d9027116a10dbd.html and https://github.com/unfor19/terraform-aws-ssm-parameters/blob/master/main.tf
  



