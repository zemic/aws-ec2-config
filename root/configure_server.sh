#!/bin/sh

# Update system packages.
echo "=====> Update system packages..."
yum update -y

# Install YARN
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
yum install yarn -y

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Update AWS CLI.
echo "=====> Update AWS CLI..."
pip install --upgrade awscli
pip install --upgrade pip

# Set our AWS CLI profile. We can pass this in when calling the script.
if [ ${1} ]; then
    AWS_REGION_NAME=${1}
else
    AWS_REGION_NAME="ap-southeast-2"
fi

echo "=====> Set AWS CLI profile..."
export AWS_DEFAULT_PROFILE=${AWS_REGION_NAME}

# Install latest version of AWS CodeDeploy.
echo "=====> Install latest verison of AWS CodeDeploy..."
cd /root/
/usr/bin/aws s3 cp s3://aws-codedeploy-${AWS_REGION_NAME}/latest/install . --quiet --region ${AWS_REGION_NAME}
chmod +x ./install
./install auto
rm -rf ./install

# Check if AWS CodeDeploy service is running, if not start it.
echo "=====> Check if CodeDeploy is running..."
codedeploy_running='pgrep codedeploy'
if [[ -n "$codedeploy_running" ]]; then
    echo "Start CodeDeploy agent..."
    service codedeploy-agent start
fi

# Virtual host files
if [ ! -d "/var/www/vhosts" ]; then
    mkdir -p /var/www/vhosts/
    chown root:root /var/www/vhosts/
fi

# Virtual Host Configuration
if [ ! -d "/etc/httpd/vhosts" ]; then
    mkdir -p /etc/httpd/vhosts/
    chown root:root /etc/httpd/vhosts/
fi

# Copy latest PHP configuration from S3
echo "=====> Update php.ini"
rm -rf /etc/php.ini
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/php.ini /etc/php.ini --quiet --region ${AWS_REGION_NAME}

# Copy latest Apache HTTPD configuration from S3
echo "=====> Update Apache configuration"
rm -rf /etc/httpd/conf/httpd.conf
rm -rf /etc/httpd/conf.d/cross-origin.conf
rm -rf /etc/httpd/conf.d/performance.conf
rm -rf /etc/httpd/conf.d/security.conf
rm -rf /etc/httpd/conf.d/wordpress-config.txt
rm -rf /etc/httpd/vhosts/0-default.conf
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/conf.d/cross-origin.conf /etc/httpd/conf.d/cross-origin.conf --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/conf.d/performance.conf /etc/httpd/conf.d/performance.conf --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/conf.d/security.conf /etc/httpd/conf.d/security.conf --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/conf.d/wordpress-config.txt /etc/httpd/conf.d/wordpress-config.txt --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/etc/httpd/vhosts/0-default.conf /etc/httpd/vhosts/0-default.conf --quiet --region ${AWS_REGION_NAME}

# Copy latest Apache HTTPD configuration from S3
echo "=====> Copy healthcheck site folder"
if [ ! -d "/var/www/vhosts/healthcheck" ]; then
    mkdir -p /var/www/vhosts/healthcheck/
    chown root:root /var/www/vhosts/healthcheck/
fi
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/var/www/vhosts/healthcheck/index.htm /var/www/vhosts/healthcheck/index.htm --quiet --region ${AWS_REGION_NAME}
/usr/bin/aws s3 cp s3://${AWS_S3_BUCKET}/ec2/var/www/vhosts/healthcheck/healthcheck.htm /var/www/vhosts/healthcheck/healthcheck.htm --quiet --region ${AWS_REGION_NAME}

echo "=====> Restart Apache"
systemctl restart httpd.service

echo "=====> EC2 Setup Complete!"
