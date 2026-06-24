FROM nginx:alpine

# Configuration nginx (port 80, gzip, fallback index.html)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Page statique (HTML + JS + CSS) — toutes les autres deps sont chargées via CDN
COPY index.html app.js lib.js style.css /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
    CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
