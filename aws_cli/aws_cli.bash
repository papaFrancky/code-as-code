#!/bin/bash


# AWS credentials
aws_access_key_id=
aws_secret_access_key=
export aws_access_key_id aws_secret_access_key

VPC_Name="console"
Region="eu-west-3"
Name="awscli-bastion"



# INSTANCE PROFILE
# ----------------

Policy_List=" route53-upsert-records
              s3-bastion-access
              ec2-describe-instances
              ec2-describe-tags"


# creation du role ec2 pour l'instance
aws iam create-role     \
  --region ${Region}    \
  --role-name "${Name}" \
  --assume-role-policy-document file://files/policy_ec2_trust.json


# definition des policies liees au role de l'instance
for Policy in ${Policy_List}; do
  aws iam put-role-policy     \
    --region ${Region}        \
    --role-name "${Name}"     \
    --policy-name "${Policy}" \
    --policy-document file://files/${Policy}.json
done


# creation de l'instance-profile
  aws iam create-instance-profile \
    --region ${Region}            \
    --instance-profile-name "${Name}" 


# rattachement du role a l'instance-profile
  aws iam add-role-to-instance-profile  \
    --region ${Region}                  \
    --instance-profile-name "${Name}"   \
    --role-name "${Name}"



# SECURITY-GROUP
# --------------

# recuperation de l'id du vpc
VPC_Id=$( aws ec2 describe-vpcs                           \
            --region ${Region}                            \
            --filters Name=tag:Name,Values="${VPC_Name}"  \
            --query 'Vpcs[].VpcId'                        \
            --output text                                 )


# creation du security-group
aws ec2 create-security-group --region ${Region} --group-name ${Name} --description "${Name}" --vpc-id ${VPC_Id}


# recuperation de l'id du security-group
SG_Id=$(  aws ec2 describe-security-groups                                        \
            --region=${Region}                                                    \
            --filters Name=vpc-id,Values=${VPC_Id} Name=group-name,Values=${Name} \
            --query 'SecurityGroups[].GroupId'                                    \
            --output=text
 )


# Apposition du tag 'Name'
aws ec2 create-tags --resources ${SG_Id} --tags Key=Name,Value=${Name}


# Creation des regles de firewall en entree
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol tcp  --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --region ${Region} --group-id ${SG_Id} --protocol icmp --port -1 --cidr 0.0.0.0/0



# EC2 INSTANCE CREATION
- name: definition de l'autoscaling launch configuration
  ec2_lc:
    region: "{{ region }}"
    state: present
    name: "lc-{{ Name }}"
    image_id: "{{ amazon_linux }}"
    key_name: "{{ Name }}"
    instance_profile_name: "instance-profile-{{ Name }}"
    security_groups: [ "{{ sg_id.stdout }}" ]
    instance_type: "{{ instance_type }}"
    assign_public_ip: no
    #user_data: "{{ lookup('file', '../files/user_data') }}"
    volumes:
      - device_name: "/dev/xvda"
        volume_size: 20
        volume_type: gp2
        delete_on_termination: true