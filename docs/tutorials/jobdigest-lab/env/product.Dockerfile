# The product's image: Python and the four packages the product's requirements.txt names, nothing else.
FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN pip install --no-cache-dir --root-user-action=ignore \
    Flask==3.1.3 gunicorn==26.2.0 honcho==2.0.0 requests==2.34.2
WORKDIR /app
