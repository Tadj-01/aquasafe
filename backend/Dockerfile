FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Set work directory
WORKDIR /app

# Install system dependencies (needed for psycopg2, curl healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application and database migrations
COPY app/ ./app/
COPY migrations/ ./migrations/
COPY alembic.ini .
COPY seed.py .

# Create directory for photo uploads
RUN mkdir -p uploads

# Create startup script that runs migrations and seeds default admin, then starts uvicorn
RUN echo '#!/bin/sh\n\
echo "Running database migrations..."\n\
alembic upgrade head\n\
echo "Running seed script..."\n\
python seed.py || true\n\
echo "Starting Uvicorn server on port $PORT..."\n\
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expose port (Render sets $PORT dynamically)
EXPOSE 8000

# Start application via entrypoint script
CMD ["/app/start.sh"]
