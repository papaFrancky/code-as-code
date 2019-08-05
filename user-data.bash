#!/bin/bash


####################  FUNCTIONS & VARS  ####################

# Ansible install
installAnsible() {
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  sudo python get-pip.py
  sudo pip install ansible boto3 paramiko cryptography
}

# Retrieve the ansible code from the S3 bucket
getAnsibleCode() {
  aws s3 sync s3://demo-infra-s3-bucket/bastion .
}

# Run the ansible playbook
runAnsibleCode () {
  ansible-playbook -c local site.yml
}


####################  CORE  ####################

installAnsible
getAnsibleCode
runAnsibleCode

