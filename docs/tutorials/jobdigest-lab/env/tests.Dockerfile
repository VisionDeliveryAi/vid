# The tests' image: pytest, a browser (Chromium, through Playwright) and the plugins the run uses.
FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN pip install --no-cache-dir --root-user-action=ignore \
    pytest==9.2.0 pytest-timeout==2.4.0 pytest-playwright==0.10.0 playwright==1.64.1 requests==2.34.2 \
 && playwright install --with-deps --only-shell chromium
