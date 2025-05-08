FROM public.ecr.aws/lambda/python:3.9

COPY lambda_function_s3.py ${LAMBDA_TASK_ROOT}

COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install --target "${LAMBDA_TASK_ROOT}" -r requirements.txt

CMD ["lambda_function_s3.lambda_handler"]