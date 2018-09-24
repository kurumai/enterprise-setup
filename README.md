# CircleCI Enterprise Setup

This repository allows you to easily orchestrate your CCIE cluster in AWS using Terraform.

## Documentation

You can find instructions here: https://circleci.com/docs/2.0/aws/

### Variables

There are some optional variables that aren't described in the instructions.
You can view their names and descriptions in [variables.tf](variables.tf).

### Teardown

1.  
    1. If you set `services_termination_protection_disabled=false` in `terraform.tfvars`, skip this step.
    
    1. Manually disable termination protection in the AWS UI.  To do this, go to the EC2 Management Console, locate the services box instance, select it and click `Actions` -> `Change Termination Protection`.

1.
    1. If you set `force_destroy_s3_bucket=true` in `terraform.tfvars`, skip this step.
    1. In the AWS Management Console, locate the S3 bucket associated with your CircleCI cluster and delete all its contents.

1. Run `terraform destroy` to destroy all EC2 instances, IAM roles, ASGs and Launch configurations created by `terraform apply`.
