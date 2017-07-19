http {

  ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
  ssl_prefer_server_ciphers on;
  ssl_ciphers 'kEECDH+ECDSA+AES128 kEECDH+ECDSA+AES256 kEECDH+AES128 kEECDH+AES256 kEDH+AES128 kEDH+AES256 DES-CBC3-SHA +SHA !aNULL !eNULL !LOW !MD5 !EXP !DSS !PSK !SRP !kECDH !CAMELLIA !RC4 !SEED';
  ssl_session_cache shared:SSL:20m;
  ssl_session_timeout 10m;
  ssl_dhparam /app/proxy/dhparam.pem;

  server {

    listen 80;
    listen 443 default_server ssl;

    ssl_certificate_key /etc/ssl/pontem/privkey1.pem;
    ssl_certificate /etc/ssl/pontem/fullchain1.pem;

    server_name www.${domain_name};
    if ($scheme = http) {
      return 301 https://$server_name$request_uri;
    }

    location / {
      resolver 127.0.0.11;
      proxy_pass ${service_address}$is_args$args;
    }
  }

  server {
    listen 80;
    listen 443;

    ssl_certificate_key /etc/ssl/pontem/privkey1.pem;
    ssl_certificate /etc/ssl/pontem/fullchain1.pem;

    server_name ${domain_name};
    return 301 https://www.$server_name$request_uri;
  }
}

events {
  worker_connections 1024;
}
