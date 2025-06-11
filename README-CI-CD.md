# Data-marketplace infrastructure

This changed code can be used to create infrasturcture which includes for services of data marketplace.

### Pre-requisites:

* You need to create an AWS EC2 instance on Default VPC (172.xx.xx.xx/xx)  
* And in a _PRIVATE  SUBNET_.  
* Remember that no SSH or any other IP based access would work  
* You need to access through AWS SSM Connect access.  
* And remember you need to update the instance profile too that making sure GitHub Actions Pipelines can access that instance.  
* e.g. `GitHubxxxxxxxxxxxx` Role  
* And attach an instance role & profile that have the rights to run required operations.  
* e.g. `xxx-xxx-instance-profile-role`  
* 
* Install git: https://linux.how2shout.com/how-to-install-git-on-aws-ec2-amazon-linux-2/
* Install Terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli (Required version - Terraform v1.5.7)
* Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
* Install awscli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
* a domain name and tls certificate for the domainname.
* SSO settings on the security.gov.uk

### For Environment Creation:
We set up GitHub Actions Pipeline.  
Steps to use the pipeline:  
* Login into GitHub with your credentials  
* Go to this repo location  
* Go To "Actions" (on the top ribbon 4th one from left)  
* Choose (click) "environment-configuration-update" pipeline (on the left Actions / All Workflows / 3rd entry). 
* Then click on the right in the blue highlighted section, dropdown menu" Run Workflow.  
* From the dropdown menu choose your desired branch, like "main" or feature/foo  
* Then you'll be represented with multiple choices of  
** Select environment  
** Select Git Branch to Clone  
** MSSQL Snapshot Name  
** POSTGRES Snapshot Name  
** Terraform With Approvals  
The last option would have choices of  
- **'init+plan'**  
- **'init+plan+apply'**  
- **'approval+destroy'**  
As it describes you can Terraform with those options.

### Installing the platform from scratch
Choose 'init+plan+apply' option.  
This will run in order of  
**`terraform init`**  
**`terraform plan`**  
**`terraform apply`**  
Then click on the green "Run Workflow" button  
Once pipeline starts running you can see visual representation of pipeline on GitHub UI.  
First you'll see dark beige animated circle and "environment-configuration-update" appears after a some delay (typically around 15 seconds)  
If you click to that newly appeared link you'll go to visual representation / graphical view of pipeline.  
Once pipeline is running you can click on the activated section of the Job Boxes to see what is going on in the pipeline.   
One thing to attention that there is a "Manual Approve" section after plan and before apply section.  
That one opens a an issue on "Issues" section on the top ribbon (second one from left)  
That will have the "Manual Approval Required for Terraform APPLY" header.  
Once you click on the issue, you can either "approve" or "deny" the request.  
It is self explanatory and easy to complete.  
Once you click on the green "Comment" button afterwards are automated. Means that it will submit and around ten seconds later automatically close the issue, you do not need to do anything.  
Pipeline continues running, does `terraform apply` and finalise the environment creation terraform section.  

### Running config.sh for initial Parameter store configuration entries
Although this section will be automated soon, at the moment manual effort needed for it.  
* on the EC2 Linux instance checkout this repository  
* `cd data-marketplace-infrastructure/app-fast/`  
* folder with the command above  
* then run as `./config/config.sh [env]`, e.g.  
* `./config/config.sh dev`  
* This will create necessary entries at AWS Parameter Store automatically for you  

### Creating .env file entries prior to app installation
* on this repository at EC2 Linux Instance  
* `cd data-marketplace-infrastructure/app-fast/`  
* `cp .env_template .env`  
* then edit the `.env` file as filling the blanks

### Application installation
* once `.env` file is created with parameters  
* `cd app-fast` folder on this reposiotory  
* Then run `sh dm-deploy.sh install` for application installation

### Application removal uninstallation
* once `.env` file is created with parameters  
* `cd app-fast` folder on this reposiotory  
* Then run `sh dm-deploy.sh uninstall` for application uninstallation  

### Application update
* once `.env` file is created with parameters  
* `cd app-fast` folder on this reposiotory  
* Then run `sh dm-deploy.sh update` for application update

### Creating DNS entries at AWS route53
Again similar to above section this section will be automated soon, at the moment manual effort needed for it.  

* You need the obtain environment's internal ALB UI DNS Name  
* for example for the 'dev' environment **dm-dev-eks-alb-ui** from the _DEV_ Accunt.  
* EC2 --> Load Balancers --> dm-dev-eks-alb-ui  
* then you can copy (click would be enough) on DNS Name (A Record) section
* The external DNS entries that are serves public are hosted on our _PRODUCTION_ account.  
* You need to be able to login into our AWS Prod Account and switch a role that have enough permissions to edit AWS Route53 entries.  
* Once you logged in to PROD AWS Console  
* Go to Route 53 --> Hosted zones --> datamarketplace.gov.uk  
* and click for editing on `dev.datamarketplace.gov.uk` entry.  
* You'll find there a CNAME record that points out to internal DEV (as in our example) Account's `dm-dev-eks-alb-ui-xxxxxxxxxxxx.xxx.xxxxx.xxx`  
* you need to edit (or create if not exist alredy) with the current & correct ALB DNS Name  
* Then save  
* Please remember that this actions needed to be done on  
** new environment create  
** and, environment update


### Deleting Completely (destroy) the platform 

If you want to destroy the dev environment:

* Run `sh dm-deploy.sh uninstall` from the app folder.
* From the pipeline run 'approval+destroy' choice at he bottom. (Terraform With Approvals) that runs `terraform destroy`.  
* There will be "Manual Approve" section like described above. 
* Approving with "approve" on the newly created issue (like as above) activates the destroy section.
* remove kubernetes config for the environment.

### Update the services 
* `cd app`.
* Create .env file with parameters (dev.env file is a template file for .env)
* Then run `sh dm-deploy.sh update`.  
* Please attention that this could be service outage creation action that application Docker pods on Kubernetes Cluster may need to be terminated and re-created.
  
### Backup and Restore 

Backend database fuseki using EFS as persistence and its protected by AWS backup service.
Backup restore can be done manually in the event of any data loss using AWS backup restore feature.


### TODO by Code
* Add DNS record for the new environment
* CI/CD for IaC & app deployment
* Import AWS backup resource creation in IaC
