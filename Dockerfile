FROM nginx:1.27-alpine

# Drop the default nginx config and ship a minimal one that serves /usr/share/nginx/html
RUN rm -f /etc/nginx/conf.d/default.conf

COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Serve index.html for any path that doesn't resolve to a file (SPA-friendly)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Long cache for static assets (none here, but harmless)
    location ~* \.(css|js|svg|png|jpg|jpeg|gif|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # Gzip text-ish responses (the inline HTML is ~75 KB)
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/html text/css application/javascript application/json image/svg+xml;
}
EOF

# Copy the static infographic
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
