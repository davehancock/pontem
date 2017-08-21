# Pontem

Pontem is a straightforward way of configuring a basic HTTPS / SSL enabled reverse proxy.

Pontem handles the generation and configuration of TLS certificates for a given domain (through LetsEncrypt). Pontem 
uses Nginx for the proxy implementation and ships with redirect rules to forward onto a downstream service complete
with 301 redirects for common protocol / www subdomain variations i.e:

- http:<i></i>//www<i></i>.[mydomain] ---> https:<i></i>//www<i></i>.[mydomain]
- http://[mydomain] ---> https://<i></i>www<i></i>.[mydomain]
- https://[mydomain] ---> https://<i></i>www<i></i>.[mydomain]


## Usage

##### Standalone
```
docker run -p 80:80 -p 443:443 daves125125/pontem -d foo.com -s http://downstream:8081
```

##### Standalone - with email expiry notifications from LetsEncrypt
```
docker run -p 80:80 -p 443:443 daves125125/pontem -d foo.com -s http://downstream:8081 -e foo@foo.com
```

##### Remote Certificate Backup - via a configured Freighter store
```
docker run -p 80:80 -p 443:443 -e FREIGHTER_PROVIDER=dropbox -e FREIGHTER_TOKEN=SECRET daves125125/pontem \
    -d foo.com \
    -s http://downstream:8081 \
    -n foo
```

### CLI Options

```
Usage: pontem [options]

Mandatory Arguments:
-d |                  A domain name e.g. [foo.com]
-s |                  A downstream service address e.g. [http://178.0.13.23:80] OR [https://foobar:443]

Optional Arguments:
-n |                  A project name - Default: default
-e |                  An email address (for certificate expiry notifications)
-t |                  Enable test mode (uses LetsEncrypt staging environment to generate certificates to prevent rate limit breaches)
-h |                  Show usage
```

## Customization

The default template shipped with Pontem provides simple out of the box configuration to generate HTTPS certificates as well 
as forwarding all traffic to *https:<i></i>//www<i></i>.[mydomain]*.

You can provide a customised nginx template by mounting a docker volume to replace the /app/proxy/nginx.conf.tpl template file like so:

```
docker run -v /custom_template_file:/app/proxy/nginx.conf.tpl -p 80:80 -p 443:443 daves125125/pontem -d foo.com -s http://downstream:8081 -n foo
```

### Template variables

Custom templates can make use of the following variables:

- ${domain_name} - The value of the domain name passed in with the -d option
- ${service_address} - The value of the service address passed in with the -s option


The default template is as follows:

```
http {

  ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
  ssl_prefer_server_ciphers on;
  ssl_ciphers 'kEECDH+ECDSA+AES128 kEECDH+ECDSA+AES256 kEECDH+AES128 kEECDH+AES256 kEDH+AES128 kEDH+AES256 DES-CBC3-SHA +SHA !aNULL !eNULL !LOW !MD5 !EXP !DSS !PSK !SRP !kECDH !CAMELLIA !RC4 !SEED';
  ssl_session_cache shared:SSL:20m;
  ssl_session_timeout 10m;
  ssl_dhparam /app/proxy/dhparam.pem;
  ssl_ecdh_curve prime256v1:secp384r1;

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
      proxy_pass ${service_address};
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

```

## Security

The default configuration achieves an A grade marking (as of August 2017) on sites such as https://www.ssllabs.com/

![Imgur](http://i.imgur.com/P0usj0I.png)
