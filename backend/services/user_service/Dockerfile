FROM python:3.11-slim

WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Bind-mounted in docker-compose.yml so data/uploads survive container
# rebuilds - see the volumes: entry for this service.
RUN mkdir -p data static/avatars

EXPOSE 8001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
