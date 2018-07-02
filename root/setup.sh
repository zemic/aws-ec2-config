#!/bin/sh

# THIS FILE LIVES IN THE AMI

# Set the AWS region name.
if [ ${1} ]; then
    AWS_REGION_NAME=${1}
else
    AWS_REGION_NAME="ap-southeast-2"
fi

# Set the AWS config bucket name.
if [ ${2} ]; then
    AWS_S3_BUCKET=${1}
else
    AWS_S3_BUCKET="aws-bucket-name"
fi

aws s3 cp s3://${AWS_S3_BUCKET}/ec2/root/configure_server.sh /root/configure_server.sh --region ${AWS_REGION_NAME}
cd ~
chmod +x ./configure_server.sh
./configure_server.sh
rm -rf ./configure_server.sh
