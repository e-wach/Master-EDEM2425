# ⚙️ MODULE 2: Data Processing

This module focused on modern tools and techniques for processing data efficiently and at scale. It covered the full data journey—from ingestion to transformation and visualization—using both batch and streaming technologies.


## ✅ What I Learned

### 🔄 Data Ingestion  
- Using **Apache NiFi** to automate and manage data flows

### 📡 Change Data Capture (CDC)  
- Streaming database changes with **Redpanda** (Kafka-compatible)

### 🍃 NoSQL  
- Working with **MongoDB**: document models, collections, and basic queries

### 📬 Kafka  
- Using **Confluent Kafka** for real-time data streaming  
- Producing and consuming messages, working with topics and schemas

### ⚡ PySpark  
- Distributed data processing with **PySpark**  
- RDDs, DataFrames, and transformations

### 🌐 APIs  
- Building and testing APIs with **Flask** and **Swagger**

### 🛠️ DBT  
- Data modeling and transformations in the warehouse using **DBT**

### 📊 Tableau  
- Creating dashboards and visualizing data insights with **Tableau**


## 📂 What You Can Find in This Folder

- 📬 [**Kafka Assignment**](KAFKA) – Main assignment using Confluent Kafka (Docker). A streaming pipeline using Kafka with a producer that sends movie data in JSON format to a topic. A consumer processes the data and filters it and sends it to a new topic. Additionally, KSQL is used to create a stream for real-time querying of the filtered data.
- ⚡ [**PySpark Assignment**](PYSPARK) – A data analysis project multiple datasets, including data cleaning, joins, aggregations, and correlations. The final results were also loaded into a MySQL database as part of the pipeline.
