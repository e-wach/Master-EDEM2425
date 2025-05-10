# 🛒 AWS Streaming - Online Shop
This is a Proof of Concept (POC) for an online shop application built on AWS, showcasing a full-stack architecture with a focus on scalable, decoupled, and cloud-native components. The application uses a simple HTML frontend and an API backend, integrated with a relational database and various AWS services.

# 🧩 Architecture Overview
## Key Components:
- Frontend: HTML website served via App Runner.

- Backend: REST API running in a Docker container hosted on Amazon App Runner, with images stored in Amazon ECR.

- Database: Amazon RDS instance (in a private subnet).

- Messaging:

    - Amazon SNS/SQS used to send messages to the database layer asynchronously.
    - AWS Lambda listens to SQS, processes the messages, and updates RDS.

- Analytics:
    - A second Lambda function creates RDS snapshots and uploads them to an S3 bucket.
    - This helps separate the analytical workload from the transactional system.

# ⚙️ Infrastructure
All components are fully deployed using Terraform, enabling reproducible and modular infrastructure as code.
