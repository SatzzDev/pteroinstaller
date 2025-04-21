#!/bin/bash
# Auto Installer Pterodactyl Panel
set -e

echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y nginx mariadb-server php8.1 php8.1-{cli,common,gd,mysql,mbstring,xml,fpm,curl,zip,bcmath,imap} unzip curl tar git redis-server composer

echo "🛠️ Setting up MariaDB..."
sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY 'passwordku';"
sudo mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "📁 Installing Panel files..."
cd /var/www/
sudo mkdir -p pterodactyl && sudo chown -R $USER:$USER pterodactyl
cd pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz && rm panel.tar.gz

echo "🔧 Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

cp .env.example .env
php artisan key:generate --force

echo "📊 Migrating database..."
php artisan migrate --seed --force

echo "⚙️ Setup Panel config..."
php artisan p:environment:setup --author="you@example.com" --url="http://localhost" --timezone="Asia/Jakarta" --cache="redis" --session="redis" --queue="redis"
php artisan p:environment:database --host="127.0.0.1" --port=3306 --database="panel" --username="ptero" --password="passwordku"
php artisan p:user:make --email="admin@example.com"

echo "🌐 Setting up NGINX..."
sudo tee /etc/nginx/sites-available/pterodactyl > /dev/null <<EOF
server {
    listen 80;
    server_name localhost;

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "✅ Panel installed! Access it via http://localhost"
