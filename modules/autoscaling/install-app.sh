#!/bin/bash
set -e

dnf update -y
dnf install -y nginx nodejs npm

# -----------------------------
# Create Application Directory
# -----------------------------
APP_DIR=/opt/app
mkdir -p $APP_DIR
cd $APP_DIR

# -----------------------------
# Create package.json
# -----------------------------
cat > $APP_DIR/package.json <<'EOF'
{
  "name": "three-tier-app",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0"
  }
}
EOF

# -----------------------------
# Create Node.js Application
# -----------------------------
cat > $APP_DIR/server.js <<'EOF'
const express = require('express');
const mysql   = require('mysql2/promise');
const os      = require('os');

const app  = express();
const PORT = 3000;

const dbConfig = {
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
};

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', tier: 'application' });
});

app.get('/', async (req, res) => {
  try {
    const conn   = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute('SELECT NOW() AS db_time');
    await conn.end();

    res.json({
      message:  'Three-Tier App running',
      db_time:  rows[0].db_time,
      app_host: os.hostname(),
    });

  } catch (err) {
    res.status(500).json({
      error:  'DB connection failed',
      detail: err.message
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`App running on port ${PORT}`);
});
EOF

# -----------------------------
# Install Node dependencies
# -----------------------------
npm install --prefix $APP_DIR

# -----------------------------
# Create systemd Service
# -----------------------------
cat > /etc/systemd/system/nodeapp.service <<EOF
[Unit]
Description=Node.js Three-Tier Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/server.js
Restart=always

Environment=NODE_ENV=production
Environment=DB_HOST=${db_host}
Environment=DB_USER=${db_user}
Environment=DB_PASS=${db_pass}
Environment=DB_NAME=${db_name}

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# Configure Nginx Reverse Proxy
# -----------------------------
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
    listen 80;
    server_name _;

    location /health {
        proxy_pass http://127.0.0.1:3000/health;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
    }
}
EOF

rm -f /etc/nginx/conf.d/default.conf

# -----------------------------
# Start Services
# -----------------------------
systemctl daemon-reload
systemctl enable nodeapp
systemctl start nodeapp

systemctl enable nginx
systemctl restart nginx