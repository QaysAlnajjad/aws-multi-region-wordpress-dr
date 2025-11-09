import json
import boto3
import os
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        logger.info("Starting database setup Lambda function")
        
        # Import pymysql here to avoid import issues
        import pymysql
        
        # Initialize AWS clients
        secrets_client = boto3.client('secretsmanager')
        
        # Get database credentials from Secrets Manager
        master_secret_arn = os.environ['MASTER_SECRET_ARN']
        wordpress_secret_arn = os.environ['WORDPRESS_SECRET_ARN']
        
        logger.info("Retrieving master credentials from Secrets Manager")
        master_secret = secrets_client.get_secret_value(SecretId=master_secret_arn)
        master_creds = json.loads(master_secret['SecretString'])
        
        logger.info("Retrieving WordPress credentials from Secrets Manager")
        wp_secret = secrets_client.get_secret_value(SecretId=wordpress_secret_arn)
        wp_creds = json.loads(wp_secret['SecretString'])
        
        # Use host from WordPress secret, credentials from master secret
        db_host = wp_creds['host']
        db_port = wp_creds.get('port', 3306)
        
        logger.info(f"Connecting to database host: {db_host}")
        
        # Connect to MySQL using master credentials but WordPress host
        connection = pymysql.connect(
            host=db_host,
            user=master_creds['username'],
            password=master_creds['password'],
            port=int(db_port),
            charset='utf8mb4'
        )
        
        logger.info("Connected to MySQL successfully")
        
        with connection.cursor() as cursor:
            # Create WordPress database
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {wp_creds['dbname']}")
            logger.info(f"Database {wp_creds['dbname']} created/verified")
            
            # Create WordPress user
            cursor.execute(f"CREATE USER IF NOT EXISTS '{wp_creds['username']}'@'%' IDENTIFIED BY '{wp_creds['password']}'")
            logger.info(f"User {wp_creds['username']} created/verified")
            
            # Grant permissions
            cursor.execute(f"GRANT ALL PRIVILEGES ON {wp_creds['dbname']}.* TO '{wp_creds['username']}'@'%'")
            cursor.execute("FLUSH PRIVILEGES")
            logger.info("Permissions granted and flushed")
            
        connection.commit()
        connection.close()
        
        logger.info("Database setup completed successfully")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database setup completed successfully',
                'database': wp_creds['dbname'],
                'user': wp_creds['username'],
                'host': db_host
            })
        }
        
    except Exception as e:
        logger.error(f"Error setting up database: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Database setup failed'
            })
        }