FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir \
        fastapi==0.110.0 \
        "uvicorn[standard]==0.29.0" \
        pydantic==2.6.4

COPY main.py /app/main.py
COPY assets /app/assets

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
