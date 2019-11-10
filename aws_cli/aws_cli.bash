#!/bin/bash


# AWS credentials
aws_access_key_id=
aws_secret_access_key=
export aws_access_key_id aws_secret_access_key

VPC_Name="demo"
Region="eu-west-3"
AZ="demo-public-${Region}a"
Instance_Name="awscli-bastion"
Instance_Type="t2.micro"
Key_Name="bastion"



# INSTANCE PROFILE
# ----------------

Policies_List=" route53-upsert-records
                s3-bastion-access
                ec2-describe-instances
                ec2-describe-tags"


# creation du role ec2 pour l'instance
aws iam create-role               \
  --region ${Region}              \
  --role-name "${Instance_Name}"  \
  --assume-role-policy-document file://files/policy_ec2_trust.json


# definition des policies liees au role de l'instance
for Policy in ${Policies_List}; do
  aws iam put-role-policy           \
    --region ${Region}              \
    --role-name "${Instance_Name}"  \
    --policy-name "${Policy}"       \
    --policy-document file://files/${Policy}.json
done


# creation de l'instance-profile
  aws iam create-instance-profile \
    --region ${Region}            \
    --instance-profile-name "${Instance_Name}" 


# rattachement du role a l'instance-profile
  aws iam add-role-to-instance-profile          \
    --region ${Region}                          \
    --instance-profile-name "${Instance_Name}"  \
    --role-name "${Instance_Name}"



# SECURITY-GROUP
# --------------

# recuperation de l'id du vpc
VPC_Id=$( aws ec2 describe-vpcs                           \
            --region ${Region}                            \
            --filters Name=tag:Name,Values="${VPC_Name}"  \
            --query 'Vpcs[].VpcId'                        \
            --output text                                 )


# creation du security-group
aws ec2 create-security-group       \
  --region ${Region}                \
  --group-name ${Instance_Name}     \
  --description "${Instance_Name}"  \
  --vpc-id ${VPC_Id}


# recuperation de l'id du security-group
SG_Id=$(  aws ec2 describe-security-groups                                                  \
            --region ${Region}                                                              \
            --filters Name=vpc-id,Values=${VPC_Id} Name=group-name,Values=${Instance_Name}  \
            --query 'SecurityGroups[].GroupId'                                              \
            --output=text )


# Apposition du tag 'Name'
aws ec2 create-tags     \
  --region ${Region}    \
  --resources ${SG_Id}  \
  --tags Key=Name,Value=${Instance_Name}


# Creation des regles de firewall en entree
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol icmp --port -1 --cidr 0.0.0.0/0



# EC2 INSTANCE CREATION

AMI_Id=$( aws ssm get-parameters                                                  \
            --region ${Region}                                                    \
            --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
            --query 'Parameters[].Value'                                          \
            --output text )


Subnet_Id=$( aws ec2 describe-subnets               \
            --region ${Region}                      \
            --filters Name=tag:Name,Values="${AZ}"  \
            --query Subnets[].SubnetId              \
            --output text )

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
  --user-data file://files/user-data.bash       \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=cost-center,Value=cc123}]' 'ResourceType=volume,Tags=[{Key=cost-center,Value=cc123}]' 
  #--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${Instance_Name}}]" 

  # aws ec2 describe-instances --query Reservations[].Instances[].InstanceId --filters "Name=tag:Name,Values=awscli-bastion"

Instance_Id=$(  aws ec2 describe-instances --query Reservations[].Instances[].InstanceId | \
                sort | tail -1 | sed 's/["|,]//g' | awk '{print $1}' )

# Apposition du tag 'Name'
aws ec2 create-tags     \
  --region ${Region}    \
  --resources ${Instance_Id}  \
  --tags Key=Name,Value=${Instance_Name}

  


