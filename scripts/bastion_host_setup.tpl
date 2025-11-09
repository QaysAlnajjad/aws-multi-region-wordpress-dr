#!/bin/bash
sudo apt update -y
sudo apt install mysql-client curl unzip jq -y

# install AWS CLI
echo "installing aws-cli"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo rm -rf aws*

# Template variables from Terraform
WORDPRESS_SECRET_ARN="${wordpress_secret_arn}"
RDS_MASTER_SECRET_ARN="${rds_master_secret_arn}"
REGION="${region}"

sleep 120

echo "Starting database setup at $(date)" >> /var/log/db-setup.log

# Get RDS master credentials (admin user)
MASTER_SECRET=$(aws secretsmanager get-secret-value --secret-id "$RDS_MASTER_SECRET_ARN" --region "$REGION" --query SecretString --output text)
MASTER_USER=$(echo $MASTER_SECRET | jq -r '.username')
MASTER_PASS=$(echo $MASTER_SECRET | jq -r '.password')

# Get WordPress user details to create
WP_SECRET=$(aws secretsmanager get-secret-value --secret-id "$WORDPRESS_SECRET_ARN" --region "$REGION" --query SecretString --output text)
WP_USER=$(echo $WP_SECRET | jq -r '.username')
WP_PASS=$(echo $WP_SECRET | jq -r '.password')
WP_DBNAME=$(echo $WP_SECRET | jq -r '.dbname')
DB_HOST=$(echo $WP_SECRET | jq -r '.host')

# Use master credentials to create WordPress database and user
mysql -h "$DB_HOST" -u "$MASTER_USER" -p"$MASTER_PASS" << EOF
CREATE DATABASE IF NOT EXISTS $WP_DBNAME;
CREATE USER IF NOT EXISTS '$WP_USER'@'%' IDENTIFIED BY '$WP_PASS';
GRANT ALL PRIVILEGES ON $WP_DBNAME.* TO '$WP_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "Database setup completed at $(date)" >> /var/log/db-setup.log
