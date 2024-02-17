# app/Dockerfile
FROM python:3.8-slim
WORKDIR /app
COPY requirements.txt .
RUN python -m venv env && . env/bin/activate pip install --no-cache-dir -r requirements.txt
COPY . .
CMD [". /app/env/bin/activate flask", "run"]
ENTRYPOINT ["/app/entrypoint.sh"]
