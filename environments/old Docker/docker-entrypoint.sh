#!/bin/bash
set -e

# Database credentials are injected as environment variables by ECS Execution Role
echo "Using database credentials from environment variables..."
echo "Database host: $WORDPRESS_DB_HOST"
echo "Database name: $WORDPRESS_DB_NAME"
echo "Database user: $WORDPRESS_DB_USER"

# Wait for database connection
echo "Testing database connection..."
for i in {1..30}; do
    if mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        echo "Database connection successful!"
        break
    fi
    echo "Attempt $i/30: Waiting for database..."
    sleep 2
done

# Create database if needed
mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $WORDPRESS_DB_NAME;"

# Copy wp-config.php to correct location
cp /tmp/wp-config.php /var/www/html/wp-config.php

# Initialize WordPress if database is empty
cd /var/www/html
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Installing WordPress to empty database..."
    wp core install \
        --url="http://localhost" \
        --title="My Business Website" \
        --admin_user="admin" \
        --admin_password="admin123" \
        --admin_email="admin@mybusiness.com" \
        --allow-root
    
    # Activate default WordPress theme
    wp theme activate twentytwentyfour --allow-root
    
    # Create sample business content with images
    wp post create --post_type=page --post_title="About Us" --post_content="<h2>Welcome to Our Company</h2><p>We provide excellent services and have been in business for many years.</p><div class='services-grid'><div class='service-item'><h3>Professional Services</h3><p>Top-quality services tailored to your needs.</p></div><div class='service-item'><h3>Expert Consultation</h3><p>Experienced team to help grow your business.</p></div><div class='service-item'><h3>24/7 Support</h3><p>Round-the-clock customer service.</p></div></div>" --post_status=publish --allow-root
    wp post create --post_title="Welcome to Our Business" --post_content="<p>This is our first blog post. We're excited to share our expertise with you!</p><p>Our company has been serving customers for years with dedication and professionalism.</p>" --post_status=publish --allow-root
    
    echo "WordPress installation completed!"
else
    echo "WordPress already installed, updating URLs and activating theme..."
    
    # Update WordPress URLs to use HTTP (ALB serves HTTP)
    if [ -n "$WORDPRESS_URL" ]; then
        wp option update home "$WORDPRESS_URL" --allow-root
        wp option update siteurl "$WORDPRESS_URL" --allow-root
        echo "WordPress URLs updated to: $WORDPRESS_URL"
    fi
    
    # Disable HTTPS redirects - ALB handles HTTP, CloudFront handles HTTPS
    wp option delete force_ssl_admin --allow-root 2>/dev/null || true
    wp option delete FORCE_SSL_ADMIN --allow-root 2>/dev/null || true
    
    # List available themes and activate a working one
    echo "Available themes:"
    wp theme list --allow-root
    
    # Try to activate twentytwentyfour (default WordPress theme)
    if wp theme activate twentytwentyfour --allow-root 2>/dev/null; then
        echo "Theme activated: twentytwentyfour"
    else
        echo "Activating first available theme..."
        FIRST_THEME=$(wp theme list --status=inactive --field=name --allow-root | head -1)
        wp theme activate "$FIRST_THEME" --allow-root
        echo "Theme activated: $FIRST_THEME"
    fi
fi





# Plugin activation

# Plugin activation (run only after WP is installed)
echo "Activating S3 plugin..."
wp plugin activate amazon-s3-and-cloudfront --allow-root

# Force S3 plugin configuration with IAM roles
echo "Configuring S3 plugin with IAM roles..."
wp option delete as3cf_settings --allow-root 2>/dev/null || true

# Create a PHP file to set the as3cf options (avoids JSON/quoting issues)
cat > /tmp/set-as3cf.php <<'PHP'
<?php
$settings = array(
  'provider' => 'aws',
  'use-server-roles' => true,
  'bucket' => getenv('AWS_S3_BUCKET'),
  'region' => 'us-east-1',
  'copy-to-s3' => true,
  'serve-from-s3' => true,
  'remove-local-file' => false,
  'object-prefix' => 'wp-content/uploads/',
  'use-yearmonth-folders' => true,
  'object-versioning' => false
);

update_option('as3cf_settings', $settings);
update_option('as3cf_provider', 'aws');
update_option('as3cf_aws_use_server_roles', 1);
update_option('as3cf_bucket', getenv('AWS_S3_BUCKET'));
update_option('as3cf_region', 'us-east-1');
update_option('as3cf_copy_to_s3', 1);
update_option('as3cf_serve_from_s3', 1);
PHP

# apply settings inside WP with wp-cli
wp eval-file /tmp/set-as3cf.php --allow-root

echo "S3 plugin configured and enabled successfully!"



# Set proper permissions
chown -R www-data:www-data /var/www/html

# Start Apache
exec "$@"
