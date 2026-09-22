FROM python:3.12-slim
WORKDIR /app
COPY . /app
EXPOSE 3050
ENV PYTHONUNBUFFERED=1
CMD ["python3", "server.py", "--host", "0.0.0.0", "--port", "3050"]
