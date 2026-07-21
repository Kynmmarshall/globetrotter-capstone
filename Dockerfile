# Use an official lightweight Python runtime as the base image
FROM python:3.9-slim

# Set a working directory inside the container
WORKDIR /globetrotter

# Copy dependency file first to leverage Docker layer caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source code
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Run the application
CMD ["python", "app/main.py"]
