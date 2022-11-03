#######################################################################################################################################
# Basic commands to create an EC2 instance with encryption enabled with PMK in AWS CLI.
#
# Bruna Moreira Bruno, October 2022
######################################################################################################################################

#Step1: Set up the scripting environment
#login to aws cli 
aws configure

#Step 2. Establish minimum parameters for the EC2 instance
#You need the following parameters to launch an EC2 instance: a. AMI ID, b. EC2 instance type, c. VPC ID and Subnet ID, d. Security Group ID and e. EC2 key pair name.

<<COMMENT
aws ec2 run-instances \
--image-id <ami-id> \
--instance-type <instance-type> \
--subnet-id <subnet-id> 
--security-group-ids <security-group-id> <security-group-id> … \
--key-name <ec2-key-pair-name>
COMMENT

# Getting SSH Keypair to connect to EC2 instance
kp_name=brmoreiraws
kp_id=$(aws ec2 describe-key-pairs --key-name $kp_name --query 'KeyPairs[0].KeyPairId' --output text)

# Getting default VPC. Your AWS account automatically has a default security group for the default VPC in each Region.
#aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text
#vpc_id=$(aws ec2 describe-vpcs --query 'Vpcs[?(IsDefault==`true`)].VpcId | []' --output text)

# Getting default subnet.
# subId=$(aws ec2 describe-subnets --filters {"Name=defaultForAz,Values=true","Name=vpc-id,Values=$vpcId"} --query "Subnets[*].{ID:SubnetId}" --output text)

# Getting default security-group
#sgId=$(aws ec2 describe-security-groups --filters "Name=group-name, Values=default" --query "SecurityGroups[*].GroupId" --output text)

# How to add a rule that allows SSH access from anywhere
aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launch an EC2 AMS Linux instance into your public subnet
# Support documentation here - https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html

amiId=ami-'02d0b1ffa5f16402d' #ami stands for AWS Machine Image. It's the image sku identifier
ec2_size='t2.micro'

aws ec2 enable-ebs-encryption-by-default
aws ec2 disable-ebs-encryption-by-default

aws ec2 run-instances --image-id $amiId --count 1 --instance-type $ec2_size --key-name $kp_name 
aws ec2 run-instances --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=32, Encrypted=true}' --image-id $amiId --count 1 --instance-type $ec2_size --key-name $kp_name --security-group-ids $sgId --subnet-id $subId