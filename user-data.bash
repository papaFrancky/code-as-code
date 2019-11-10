#!/bin/bash


####################  FUNCTIONS & VARS  ####################

awsRegion=$(	curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/ | sed 's/[a-z]$//' )

instanceId=$(	curl -s http://169.254.169.254/latest/meta-data/instance-id )

instanceName=$( aws ec2 describe-instances						\
			--filters Name=instance-id,Values=${instanceId}			\
			--query 'Reservations[].Instances[].Tags[?Key==`Name`].Value[]'	\
			--region=${awsRegion}						\
			--output text )

# Ansible install
installAnsible() {
  curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  sudo python get-pip.py
  sudo pip install --upgrade pip
  sudo pip install ansible boto  boto3 paramiko cryptography
}

# Retrieve the ansible code from the S3 bucket
getAnsibleCode() {
  [ -d /install ] && /bin/rm -rf /install
  mkdir /install
  aws s3 sync s3://demo-infra-s3-bucket/${instanceName} /install/. --region=${awsRegion}
}

# Run the ansible playbook 
runAnsibleCode () {
  cd /install
  ansible-playbook -c local site.yml
}


####################  CORE  ####################

installAnsible
getAnsibleCode
#runAnsibleCode

