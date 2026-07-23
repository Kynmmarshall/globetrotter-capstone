# trip_io backend (GlobeTrotter Phase 1 monolith) - FastAPI + uvicorn.
FROM python:3.11-slim

WORKDIR /app

# Install dependencies first so this layer is cached across code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY static ./static
COPY website ./website

# data/, website/downloads/ and website/webapp/ are runtime state - not
# baked into the image, see the volumes in docker-compose.yml. Create them
# here too so the container still works if it's run standalone (`docker run`)
# without those volumes mounted.
RUN mkdir -p data website/downloads website/webapp

ENV PYTHONUNBUFFERED=1
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
