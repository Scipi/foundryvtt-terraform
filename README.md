# Setup of FoundryVTT in AWS using Terraform
This guide assumes some familarity with AWS and limited familiarity with Terraform. I wrote it to get better at Terraform.

# Prerequisites
 - A domain that you control and can update the DNS records to point to AWS Route53
 - A valid license for [Foundry VTT](https://foundryvtt.com)
 - An AWS account, with an IAM user with admin acces, access key and secret access key.
 - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed on your machine
 - Terraform installed in your PATH
 - Packer installed and in your PATH

# Setup
This setup requires two tools - packer to create the AMI with the base foundry install, and terraform to create the infrastructure such as ec2 instances and security groups.
 1. Fork this repo
 2. Log into your AWS IAM user
 3. Create AWS access key/secret if you don't have one yet
 4. Create an EC2 instance 
    - community ami - amzn2-ami-hvm-2.0.20210701.0-x86_64-gp2
    - t2.micro
    - default ebs storage
    - key pair you have access to
 5. Stop instance
 6. Create image from instance - Name image ``foundry-base-0.1``
 7. Terminate instance

You now have a base ami you own to build a foundry-specific AMI from

 8. Open the terminal on your machine
 9. Make sure you can run packer locally by testing ``packer`` in your terminal
 10. Use ``aws configure`` to add your AWS Account, Access Key and ID
 11. . Clone this repo to your machine using ``git clone``
 12.  ``cd `` to the newly created foundryvtt-terraform
 13.   ``cd`` to packer
 14.    Download the latest version of foundry vtt to the packer directory from foundryvtt.com. It should be the linux version and it will be named something like ``foundryvtt-0.8.8.zip``
 15.     Create a file in the packer directory ``www.auto.pkrvars.hcl`` with the following variable settings
    ```
    name = "www"
    domain = "yourdomain.com"
    region = "your preferred region"
    foundryvtt = "path-to-your-zip"
    ```
 16. If running for the very first time, then run packer with the var file. e.g. ``packer build --var-file www.auto.pkrvars.hcl foundry.pkr.hcl``
 17. If you already have a Foundry Data volume and are just making a new AMI for a new release, then run packer with ``packer build -only FoundryAMI\* --var-file www.auto.pkrvars.hcl foundry.pkr.hcl``

You now have an AMI which has foundry installed on it, but no SSL certificates. You should also have a Foundry Data volume

 7. Create a Terraform workspace and point it to your new fork
 8. In the Variables section of your Terraform workspace, specify the following variables
    - home_cidr - required - your IP address to the word, followed by a /32. This will allow you to SSH to your server, and no one else. E.g. 34.56.78.90/32
    - domain - required - the domain you bought. Foundry will register itself as https://www.```${domain}```
    - public_key - required - the public key you use for ssh. On a mac or linux system it's located in ~/.ssh/id_rsa.pub. On Windows it varies based on what ssh program you use.
    - instance_size - optional - The EC2 instance type you want to use. t3a.micro works just fine.
    - region - optional - The region to deploy to. Pick one close to you and your players. 
 9.  Still in the Variables section, under environment variables, create/set the following variables (set to sensitive!)
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - AWS_DEFAULT_REGION (doesn't have to be set to sensitive)
 10. Here's what your variables screen should look like when done, if you specify all optional values:
    - ![](img/Variables.png)
 12. Queue the running of the plan.
 13. Apply the plan.
 14. The plan may not succeed the very first time (if nothing else, it will fail to get the SSL cert), but now you have Route53 set-up.
 15. In the AWS console, go to Route53, go to your hosted zone, and for your domain get the ```value/route traffic to``` values for your name servers.
 16. Wherever your registered your domain, update its DNS records to point to the values from the previous step. This may take some 10-30 minutes to propogate to the wider internet.
    - This will move all domain control away from your registrar and over to Route53 and Terraform.
 17. Terminate your ec2 instance if it's running.
 18. re-run your plan. 
 19. Log in to your FoundryVTT instance. You should be able to ssh to ec2-user@www.yourdomain.
 20. Edit the file foundrydata/Config/options.json and add the following
    ```
    "upnp": false,
    "hostname": "www.<yourdomain>",
    "dataPath": "/home/ec2-user/foundrydata",
    "proxySSL": true,
    "proxyPort": 443,
    ```
 21. Restart your foundry by executing ```sudo systemctl restart foundryvtt```
 22. Your foundry should be available at https://www.${domain}.
 23. Once you validate that your foundry is working, you will want to make an AMI of it so you don't have to get new 5-minute URLs all the time.
 24. After you make your AMI, update the variables to point to to the AMI name and owner.
