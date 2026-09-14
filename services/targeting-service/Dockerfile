FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
COPY . .
EXPOSE 8003
CMD ["gunicorn", "--bind", "0.0.0.0:8003", "app:app"]
