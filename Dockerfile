# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Instalar bash e git caso necessário
RUN apk add --no-cache git

COPY package*.json ./
RUN npm config set registry https://registry.npmjs.org/ \
    && npm config set maxsockets 3 \
    && npm ci --no-audit --prefer-offline || npm install --legacy-peer-deps --no-audit

COPY . .
RUN npm run build:web

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html

# SPA fallback configuration
RUN printf 'server {\n\
    listen 80;\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

