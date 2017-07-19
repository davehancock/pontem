# Pontem

Pontem is a straightforward way of configuring a basic HTTPS / SSL enabled reverse proxy.

Pontem handles the generation and configuration of TLS certificates for a given domain (through LetsEncrypt). Pontem 
uses Nginx for the proxy implementation and ships with redirect rules to forward onto a downstream service complete
with 301 redirects for common protocol / www subdomain variations i.e:

- http://www.[mydomain] >> https://www.[mydomain]
- http://[mydomain] >> https://www.[mydomain]
- https://[mydomain] >> https://www.[mydomain]


## Examples

##### Standalone
```
docker run -p 80:80 -p 443:443 daves125125/pontem -d foo.com -s http://downstream:8081
```

##### Standalone - with email expiry notifications from letsencrypt
```
docker run -p 80:80 -p 443:443 daves125125/pontem -d foo.com -s http://downstream:8081 -e foo@foo.com
```

##### Remote Certificate Backup - via a configured Freighter store
```
env FREIGHTER_PROVIDER=dropbox FREIGHTER_TOKEN=SECRET | docker run -p 80:80 -p 443:443 -e FREIGHTER_PROVIDER -e FREIGHTER_TOKEN daves125125/pontem -d foo.com -s http://downstream:8081 -n foo
```

## CLI Usage

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
