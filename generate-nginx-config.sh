#!/bin/bash

# 动态生成 Nginx 配置文件

# 加载环境变量
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# 设置默认值
DOMAIN=${DOMAIN:-"deepinfra.kyx03.de"}
NGINX_PORT=${NGINX_PORT:-"80"}
BACKEND_HOST=${BACKEND_HOST:-"deepinfra-proxy"}
BACKEND_PORT=${BACKEND_PORT:-"8000"}

echo "🔧 生成 Nginx 配置文件..."
echo "   域名: $DOMAIN"
echo "   Nginx 端口: $NGINX_PORT"
echo "   后端地址: $BACKEND_HOST:$BACKEND_PORT"

# 生成 nginx.conf
cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server ${BACKEND_HOST}:${BACKEND_PORT};
    }

    # 日志格式
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # HTTP 服务器配置
    server {
        listen ${NGINX_PORT};
        server_name ${DOMAIN};

        # 访问日志
        access_log /var/log/nginx/access.log main;
        error_log /var/log/nginx/error.log;

        # 主要代理配置
        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;

            # 超时设置
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # 流式响应支持
            proxy_buffering off;
            proxy_cache off;

            # CORS 支持
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

            # OPTIONS 请求处理
            if (\$request_method = 'OPTIONS') {
                add_header Access-Control-Allow-Origin * always;
                add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
                add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
                add_header Access-Control-Max-Age 1728000;
                add_header Content-Type 'text/plain charset=UTF-8';
                add_header Content-Length 0;
                return 204;
            }
        }

        # 健康检查
        location /health {
            proxy_pass http://backend/health;
            access_log off;
        }
    }
}
EOF

echo "✅ Nginx 配置文件生成完成: nginx.conf"