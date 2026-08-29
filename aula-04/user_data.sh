#!/bin/bash
# user_data.sh - Provisiona a API TechNova na instância EC2
set -e

LOGFILE=/var/log/technova-setup.log
echo "[$(date)] Iniciando setup da TechNova API" >> "$LOGFILE"

# 1. Atualizar o sistema
yum update -y >> "$LOGFILE" 2>&1

# 2. Instalar Git
yum install -y git >> "$LOGFILE" 2>&1
echo "[$(date)] Git instalado: $(git --version)" >> "$LOGFILE"

# 3. Instalar Node.js 18 via NodeSource
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash - >> "$LOGFILE" 2>&1
yum install -y nodejs >> "$LOGFILE" 2>&1
echo "[$(date)] Node instalado: $(node --version)" >> "$LOGFILE"

# 4. Criar a aplicação Express (versão simplificada da technova-api)
mkdir -p /home/ec2-user/technova-api
cd /home/ec2-user/technova-api

cat > package.json << 'EOF'
{
  "name": "technova-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF

cat > server.js << 'EOF'
const express = require('express');
const os = require('os');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'TechNova API - Rodando na AWS!',
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'technova-api' });
});

app.get('/orders', (req, res) => {
  res.json({
    orders: [
      { id: 1, product: 'Widget A', status: 'shipped' },
      { id: 2, product: 'Widget B', status: 'processing' },
    ],
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TechNova API rodando na porta ${PORT}`);
});
EOF

# 5. Instalar dependências
npm install >> "$LOGFILE" 2>&1
chown -R ec2-user:ec2-user /home/ec2-user/technova-api

# 6. Iniciar a aplicação na porta 3000
cd /home/ec2-user/technova-api
sudo -u ec2-user nohup node server.js > /home/ec2-user/technova-api/app.log 2>&1 &

echo "[$(date)] TechNova API iniciada na porta 3000" >> "$LOGFILE"
