import boto3
from datetime import datetime
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_ID = os.getenv('DB_ID', 'default-db-id')
BUCKET_NAME = os.getenv('BUCKET_NAME', 'default-bucket-name')
KMS_KEY_ID = os.getenv('KMS_KEY_ID', 'default-kms-key-id')
IAM_ROLE_ARN = os.getenv('IAM_ROLE_ARN', 'default-iam-role-arn')
ACCOUNT_ID = os.getenv('ACCOUNT_ID', 'default-account-id')
REGION = "eu-central-1"


def lambda_handler(event, context):
    logger.info("Lambda function started")
    rds_client = boto3.client('rds')
    snapshot_identifier = 'snapshot-' + datetime.today().strftime('%Y-%m-%d-%H-%M-%S')
    try:
        logger.info("Creating snapshot...")
        rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_identifier, 
            DBInstanceIdentifier=DB_ID
            )
        waiters = rds_client.get_waiter('db_snapshot_completed')
        waiters.wait(DBSnapshotIdentifier=snapshot_identifier)
        logger.info("Snapshot created.")
    except Exception as e:
        logger.error(f"Error creating snapshot: {e}")
        return {
            'statusCode': 500,
            'body': f"Error creating snapshot: {e}"
        }
    logger.info("Exporting snapshot...")
    export_task_identifier = 'export-' + datetime.today().strftime('%Y-%m-%d-%H-%M-%S')
    try:   
        s3_export_task = rds_client.start_export_task(
            ExportTaskIdentifier=export_task_identifier,
            SourceArn=f"arn:aws:rds:{REGION}:{ACCOUNT_ID}:snapshot:{snapshot_identifier}",
            S3BucketName=BUCKET_NAME,
            IamRoleArn=IAM_ROLE_ARN,
            KmsKeyId=KMS_KEY_ID,
        )
        logger.info("Snapshot exported successfully.")
        return {
            'statusCode': 200,
            'body': 'Snapshot exported successfully!'
        }
    except Exception as e:
        logger.error(f"Error exporting snapshot to S3: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error exporting snapshot to S3: {str(e)}"
        }