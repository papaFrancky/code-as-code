#!/bin/bash

# How to create an EC2 instance using the AWS CLI 

# AWS credentials
# AWS_DEFAULT_REGION=<your_aws_region>
# AWS_ACCESS_KEY_ID=<your_access_key_id>
# AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
# export AWS_DEFAULT_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY


# VARIABLES
# ---------

VPC_Name="demo"
Region="eu-west-3"
AZ="demo-public-${Region}a"
Instance_Name="awscli-bastion"
Instance_Type="t2.micro"
Key_Name="bastion"



# INSTANCE PROFILE
# ----------------

Policies_List=" route53-upsert-records
                ec2-describe-instances
                ec2-describe-tags
                s3-${Instance_Name}-access"


# IAM role creation for the EC2 instance
aws iam create-role                                     \
  --region ${Region}                                    \
  --role-name "${Instance_Name}"                        \
  --assume-role-policy-document file://files/policy_ec2_trust.json


# Policies creation
for Policy in ${Policies_List}; do
  aws iam put-role-policy           \
    --region ${Region}              \
    --role-name "${Instance_Name}"  \
    --policy-name "${Policy}"       \
    --policy-document file://files/${Policy}.json
done


# Instance profile creation
  aws iam create-instance-profile \
    --region ${Region}            \
    --instance-profile-name "${Instance_Name}" 


# Role attachment to the instance profile
  aws iam add-role-to-instance-profile          \
    --region ${Region}                          \
    --instance-profile-name "${Instance_Name}"  \
    --role-name "${Instance_Name}"



# SECURITY-GROUP
# --------------

# VPC ID retrieval
VPC_Id=$( aws ec2 describe-vpcs                           \
            --region ${Region}                            \
            --filters Name=tag:Name,Values="${VPC_Name}"  \
            --query 'Vpcs[].VpcId'                        \
            --output text                                 )


# Security group creation
aws ec2 create-security-group       \
  --region ${Region}                \
  --group-name ${Instance_Name}     \
  --description "${Instance_Name}"  \
  --vpc-id ${VPC_Id}


# Security-group ID retrieval
SG_Id=$(  aws ec2 describe-security-groups                                                  \
            --region ${Region}                                                              \
            --filters Name=vpc-id,Values=${VPC_Id} Name=group-name,Values=${Instance_Name}  \
            --query 'SecurityGroups[].GroupId'                                              \
            --output=text )


# Tagging the security group's name
aws ec2 create-tags     \
  --region ${Region}    \
  --resources ${SG_Id}  \
  --tags Key=Name,Value=${Instance_Name}


# Adding firewall rules to the security group
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol icmp --port -1 --cidr 0.0.0.0/0



# EC2 INSTANCE CREATION
# ---------------------

# AMI ID
AMI_Id=$( aws ssm get-parameters                                                  \
            --region ${Region}                                                    \
            --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
            --query 'Parameters[].Value'                                          \
            --output text )

# VPC subnet ID
Subnet_Id=$( aws ec2 describe-subnets               \
            --region ${Region}                      \
            --filters Name=tag:Name,Values="${AZ}"  \
            --query Subnets[].SubnetId              \
            --output text )


Make_Instance () {

  # Create EC2 instance
  aws ec2 run-instances                           \
    --region ${Region}                            \
    --count 1                                     \
    --instance-type ${Instance_Type}              \
    --image-id ${AMI_Id}                          \
    --security-group-ids ${SG_Id}                 \
    --key-name ${Key_Name}                        \
    --subnet-id ${Subnet_Id}                      \
    --associate-public-ip-address                 \
    --iam-instance-profile Name=${Instance_Name}  \
    --user-data file://files/user-data.bash       
  
  # Get the ID of the latest-launched EC2 instance
  Instance_Id=$(  aws ec2 describe-instances                                                  \
                  --region ${Region}                                                          \
                    --query 'sort_by(Reservations[].Instances[],&LaunchTime)[-1].InstanceId'  \
                    --output=text )

  # Associate the tag 'Name' to the instance
  aws ec2 create-tags           \
    --region ${Region}          \
    --resources ${Instance_Id}  \
    --tags Key=Name,Value=${Instance_Name}

}

Make_Instance
