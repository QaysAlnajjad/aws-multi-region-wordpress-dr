<?php
// Database configuration from environment variables
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD'));
define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// WordPress salts
define('AUTH_KEY',         'rZBxKzeSk<F+!CPvZa##m$@/1+ndxn>BXu#yJ8>r=G]CA^eKdgq/s:n`}!]m~es]');
define('SECURE_AUTH_KEY',  'tK@|q?6=m/Jd0-) 0]q}SJ4FT&n_#CGOBSV+k<,6Y7L*$-JZKo=zH4/0/3 vqOv:');
define('LOGGED_IN_KEY',    'lYE!un8RAKm-dFVWr=sl0/iA<]dCi3kGNVP 8MWx |Hz9*?SX0RR+xx#|*nuMW||');
define('NONCE_KEY',        '3*-b=<tr*>;F#J4Q#[SRMoWv]dy|E B[=qmOi*Tifx;6H_:*Vg|GNgkV.T=-8d5+');
define('AUTH_SALT',        '|G|&{JHrzg`,lLTahkJe9^KaE(f,Ze32k%;+A}:{JVK[s^pE~oW2];du&rI5#.[a');
define('SECURE_AUTH_SALT', '19U?s.qn9=8!^y.TnsX%6L79+-+T|F {}r{h7HuqA]D1{Z}}[6]crky-fD(y!rxV');
define('LOGGED_IN_SALT',   'W<37<@.yVGXt$<}ai/eybxpG2[i$OF ]mZ6;+t/{k-uD(Gl-n`aJ[?$ov5S`V!*O');
define('NONCE_SALT',       '%,;^wB|b??+X^tz.N{U+%()jQ3Q8t567;.$BfN,8U1vgmoB~C<<&^wx%h0O+a|FF');

// Production settings
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);

// Security settings
define('DISALLOW_FILE_EDIT', true);
define('AUTOMATIC_UPDATER_DISABLED', true);

// Performance settings
define('WP_CACHE', true);
define('COMPRESS_CSS', true);
define('COMPRESS_SCRIPTS', true);

// Handle HTTPS from CloudFront and ALB
if ((isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO']) && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] === 'https') ||
    (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')) {
    $_SERVER['HTTPS'] = 'on';
}

// Dynamic URL handling based on domain
if (isset($_SERVER['HTTP_HOST'])) {
    if ($_SERVER['HTTP_HOST'] === 'admin.qays.cloud') {
        // Admin domain - direct ALB access
        define('WP_HOME', 'https://admin.qays.cloud');
        define('WP_SITEURL', 'https://admin.qays.cloud');
    } else {
        // Public domain - CloudFront access
        define('WP_HOME', 'https://qays.cloud');
        define('WP_SITEURL', 'https://qays.cloud');
    }
} else {
    // Fallback to environment variable
    if (getenv('WORDPRESS_URL')) {
        define('WP_HOME', getenv('WORDPRESS_URL'));
        define('WP_SITEURL', getenv('WORDPRESS_URL'));
    }
}

// Disable HTTPS redirects - ALB handles HTTP, CloudFront handles HTTPS
define('FORCE_SSL_ADMIN', false);
define('FORCE_SSL', false);

// Force IAM role usage for S3 plugin
define('AS3CF_AWS_USE_EC2_IAM_ROLE', true);

// S3 Integration with CloudFront
define('AS3CF_SETTINGS', serialize(array(
    'provider' => 'aws',
    'use-server-roles' => true,
    'bucket' => getenv('AWS_S3_BUCKET') ?: 'wordpress-media-prod-200',
    'region' => 'us-east-1',
    'copy-to-s3' => true,
    'serve-from-s3' => true,
    'enable-object-prefix' => true,
    'object-prefix' => 'wp-content/uploads/',
    'use-yearmonth-folders' => true,
    'cloudfront' => getenv('CLOUDFRONT_DOMAIN') ?: '',
    'enable-delivery-domain' => true,
    'delivery-domain' => getenv('CLOUDFRONT_DOMAIN') ?: '',
    'force-https' => true
)));

$table_prefix = 'wp_';

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
?>
