
# Stage 1: Install Python dependencies
FROM python:3.12-slim-trixie AS builder

WORKDIR /build

COPY app/requirements.txt .

RUN pip install --no-cache-dir \
    --prefix=/install \
    -r requirements.txt


# Stage 2: Runtime image
FROM python:3.12-slim-trixie

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="/opt/python/lib/python3.12/site-packages" \
    PATH="/opt/python/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       nginx \
       bash \
       ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /opt/python

WORKDIR /app

COPY app/main.py /app/main.py
COPY nginx/nginx.conf /etc/nginx/nginx.conf

RUN groupadd --system appgroup \
    && useradd --system \
       --gid appgroup \
       --home-dir /app appuser \
    && mkdir -p /tmp/nginx \
    && chown -R appuser:appgroup /app /tmp/nginx

USER appuser

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["bash", "-c", "set -m; uvicorn main:app --host 127.0.0.1 --port 8000 & app_pid=$!; nginx -g 'daemon off;' & nginx_pid=$!; trap 'kill \"$app_pid\" \"$nginx_pid\" 2>/dev/null || true; wait || true' TERM INT; wait -n \"$app_pid\" \"$nginx_pid\"; result=$?; kill \"$app_pid\" \"$nginx_pid\" 2>/dev/null || true; wait || true; exit \"$result\""]
