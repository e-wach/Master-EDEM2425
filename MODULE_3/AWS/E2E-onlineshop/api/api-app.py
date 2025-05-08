from flask import Flask, jsonify, render_template, request, redirect, url_for
import json
import logging
from flask import Flask, jsonify, render_template, request, redirect, url_for
import json
import logging
import os
import mysql.connector
from mysql.connector import Error
import uuid
import boto3
 
app = Flask(__name__)
 
logging.basicConfig(level=logging.DEBUG)
 
RDS_HOST = os.getenv('RDS_HOST', 'default-host')
RDS_USER = os.getenv('RDS_USER', 'default-user')
RDS_PASS = os.getenv('RDS_PASS', 'default-password')
RDS_DB = os.getenv('RDS_DB', 'default-db')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN', 'default-arn')
REGION = 'eu-central-1'

def get_db_connection():
    try:
        logging.info(f"Conectando a la base de datos {RDS_DB} en {RDS_HOST} con el usuario {RDS_USER}")
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
    
    except mysql.connector.Error as e:
        logging.error(f"Error al conectar a la base de datos: {e}")
        return None
 
 
items = [
     {"id": 1, "name": "Hozier - Hozier", "price": 45, "image_url": "https://cdn-images.dzcdn.net/images/cover/8442e9ac0227a07b00c9dfd0ec00032d/0x1900-000000-80-0-0.jpg"},
     {"id": 2, "name": "Hozier - Wasteland, Baby!", "price": 50, "image_url": "https://cdn-images.dzcdn.net/images/cover/ced08a09eb93982eb30ae9ae44a1c5ba/1900x1900-000000-80-0-0.jpg"},
     {"id": 3, "name": "Hozier - Unreal Unearth", "price": 55, "image_url": "https://www.hebronhawkeye.com/wp-content/uploads/2023/08/134C2658-0C3A-4B6C-A55D-EC88A2856F01-1200x1200.jpeg"},
 ]
 

def create_table_if_not_exists():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        create_table_query = '''
         CREATE TABLE IF NOT EXISTS products (
             id INT AUTO_INCREMENT PRIMARY KEY,
             name VARCHAR(255) NOT NULL,
             price DECIMAL(10, 2) NOT NULL,
             image_url VARCHAR(255) NOT NULL
         );
         '''
        cursor.execute(create_table_query)
        connection.commit()
        logging.info("Tabla 'products' creada.")
        
        create_orders_table_query = '''
         CREATE TABLE IF NOT EXISTS orders (
             id INT AUTO_INCREMENT PRIMARY KEY,
             client VARCHAR(255) NOT NULL,
             product VARCHAR(255) NOT NULL,
             quantity INT NOT NULL,
             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
         );
         '''
        cursor.execute(create_orders_table_query)
        connection.commit()
        logging.info("Tabla 'orders' creada.")
 
        for item in items:
            cursor.execute("SELECT * FROM products WHERE name = %s", (item["name"],))
            existing_product = cursor.fetchone()
            if not existing_product: 
                insert_query = '''
                INSERT INTO products (name, price, image_url) VALUES (%s, %s, %s)
                 '''
                cursor.execute(insert_query, (item["name"], item["price"], item["image_url"]))
                connection.commit()
                logging.info(f"Producto {item['name']} insertado.")
            else:
                print(f"Producto {item['name']} ya existe.")
 
    except Error as e:
        print(f"Error al crear la tabla: {e}")
    finally:
        cursor.close()
        connection.close()
 
 
# @app.route('/')
# def index():
#     return render_template('index.html', items=items)

@app.route('/')
def home():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM products")
        products = cursor.fetchall()
    except Error as e:
        print(f"Error al obtener productos: {e}")
        products = []
    finally:
        cursor.close()
        connection.close()
    return render_template("index.html", items=products)
 

@app.route('/getProducts', methods=['GET'])
def get_products():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM products")
        products = cursor.fetchall()
        cursor.close()
        connection.close()
    except Exception as e:
        logging.error(e)
    return jsonify(products)


@app.route('/addProduct', methods=['GET'])
def add_product_form():
    return render_template('add_product.html')


@app.route('/postProduct', methods=['POST'])
def add_product():
    try:
        if "name" not in request.form or "price" not in request.form or "image_url" not in request.form:
            return jsonify({"error": "Missing required form fields"}), 400
        
        name = request.form["name"]
        image_url = request.form["image_url"]
        try:
            price = float(request.form["price"])
        except ValueError:
            return jsonify({"error": "Invalid price format"}), 400
        new_product = {
            "name": name,
            "price": price,
            "image_url": image_url
        }
        sns_client = boto3.client('sns', region_name=REGION)
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(new_product),
            Subject="New product added"
            # MessageStructure="json"
            )
            
        return f"New product added successfully {new_product['name']}"
    except Exception as e:
        logging.error(e)
        return jsonify({"error": str(e)}), 500


@app.route('/getOrders', methods=['GET'])
def get_orders():
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM orders")
        orders = cursor.fetchall()
        cursor.close()
        connection.close()
        return jsonify(orders)
    except Exception as e:
        logging.error(e)
     
 
@app.route('/postOrder', methods=['POST'])
def buy_product():
    try:
        client = str(uuid.uuid4())
        product = request.form["name"]
        quantity = int(request.form["quantity"])
        new_order = {"client": client, 
                     "product": product, 
                     "quantity": quantity
                     }
        connection = get_db_connection()
        cursor = connection.cursor()
        insert_order_query = '''
            INSERT INTO orders (client, product, quantity) 
            VALUES (%s, %s, %s);
         '''
        cursor.execute(insert_order_query, 
                       (client, product, quantity))
        connection.commit()
        cursor.close()
        connection.close()
        return redirect(url_for("home"))
    except Exception as e:
        logging.error(e)
     
 
 
if __name__ == '__main__':
    logging.info("Initializing database...")
    create_table_if_not_exists()
    logging.info("Starting Flask app...")
    logging.info(f"RDS HOST {RDS_HOST}")
    try:    
        app.run(host='0.0.0.0', port=8000)
    except Exception as e:
        logging.error(f"Error starting Flask app: {e}")