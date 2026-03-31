FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Wait a few seconds for Temporal to be fully ready, then start the worker.
# In production you'd use a proper health-check loop instead of sleep.
CMD ["sh", "-c", "sleep 5 && python run_worker.py"]
