#!/bin/bash

read -p "Enter AWS region (e.g., us-east-1): " AWS_REGION
read -p "Enter VPC CIDR block (e.g., 10.0.0.0/16): " VPC_CIDR_BLOCK
read -p "Enter private subnet CIDR block (e.g., 10.0.1.0/24): " PRIVATE_SUBNET_CIDR_BLOCK
read -p "Enter public subnet CIDR block (e.g., 10.0.2.0/24): " PUBLIC_SUBNET_CIDR_BLOCK
read -p "Enter key name (e.g., Avag-Test-Vps): " KEY_NAME
read -p "Enter private subnet name: " PRIVATE_SUBNET_NAME_TAG
read -p "Enter public subnet name: " PUBLIC_SUBNET_NAME_TAG
read -p "Enter instance tag key: " INSTANCE_TAG_KEY
read -p "Enter instance tag value: " INSTANCE_TAG_VALUE
read -p "Enter VPC tag name: " VPC_NAME_TAG
AMI_ID="ami-0a0e5d9c7acc336f1"
INSTANCE_TYPE="t2.micro"

sudo apt update
sudo apt upgrade -y

VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR_BLOCK --query 'Vpc.VpcId' --output text)
echo "Created VPC with ID: $VPC_ID"

aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME_TAG
echo "Created VPC with name: $VPC_NAME_TAG"

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_CIDR_BLOCK --query 'Subnet.SubnetId' --output text)
echo "Created Private Subnet with ID: $PRIVATE_SUBNET_ID"

PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR_BLOCK --query 'Subnet.SubnetId' --output text)
echo "Created Public Subnet with ID: $PUBLIC_SUBNET_ID"

aws ec2 create-tags --resources $PRIVATE_SUBNET_ID --tags Key=Name,Value=$PRIVATE_SUBNET_NAME_TAG
echo "Tagged Private Subnet with Name: $PRIVATE_SUBNET_NAME_TAG"

aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=Name,Value=$PUBLIC_SUBNET_NAME_TAG
echo "Tagged Public Subnet with Name: $PUBLIC_SUBNET_NAME_TAG"

# Create a new security group in the same VPC
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name MySecurityGroup --description "My security group" --vpc-id $VPC_ID --query 'GroupId' --output text)
echo "Created Security Group with ID: $SECURITY_GROUP_ID"

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $PUBLIC_SUBNET_ID \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "Launched EC2 Instance with ID: $INSTANCE_ID"

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=$INSTANCE_TAG_KEY,Value=$INSTANCE_TAG_VALUE
echo "Tagged EC2 Instance with Key: $INSTANCE_TAG_KEY and Value: $INSTANCE_TAG_VALUE"
