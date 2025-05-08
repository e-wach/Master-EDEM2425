import os
import logging
import json
import mysql.connector

logging.basicConfig(level=logging.DEBUG)

RDS_HOST = os.getenv('RDS_HOST', 'default-host')
RDS_USER = os.getenv('RDS_USER', 'default-user')
RDS_PASS = os.getenv('RDS_PASS', 'default-password')
RDS_DB = os.getenv('RDS_DB', 'default-db')
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL', 'default-queue-url')
REGION = 'eu-central-1'


def get_db_connection():
    connection = mysql.connector.connect(
        host=RDS_HOST.split(':')[0],
        user=RDS_USER,
        password=RDS_PASS,
        port=3306,
        database=RDS_DB
        )
    if connection.is_connected():
        print(f"Conectado a la base de datos {RDS_DB}")
    else:
        logging.error("Error al conectar a la base de datos")
    return connection
    

def insert_data(item, connection):
    try:
        name = item.get('name')
        price = item.get('price')
        image_url = item.get('image_url')
        new_product = {"name": name, 
                       "price": price, 
                       "image_url": image_url
                       }
        cursor = connection.cursor()
        query_mysql_insert = """
            INSERT INTO products (name, price, image_url)
            VALUES (%s, %s, %s);
        """
        cursor.execute(query_mysql_insert, 
                       (name, price, image_url))
        connection.commit()
        cursor.close()
        return True
    except Exception as e:
        logging.error(e)
        return False


def lambda_handler(event, context):
    connection = get_db_connection()
    records = event.get('Records', [])
    if not records:
        logging.warning("No 'Records' found in event. Event received: %s", event)
        return {
            'statusCode': 400,
            'body': 'No records to process.'
        }
    for record in records:
        try:
            sns_message = json.loads(record['body'])
            message_body = json.loads(sns_message['Message'])
            logging.info(f"Processing message: {message_body}")
            insert_data(message_body, connection)
        except Exception as e:
            logging.error(f"Error in lambda_handler: {e}")
    connection.close()
    return {
            'statusCode': 200,
            'body': 'Processed {} records.'.format(len(event['Records']))
            }
    


