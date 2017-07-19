#!/usr/bin/env bash

certificate_location="/etc/ssl/pontem"

function is_certificate_valid() {

    local backup_archive_name="$1"

    echo "Checking if certificates are valid..." >&2
    freighter age /${backup_archive_name}.tar.gz --output /tmp/age >&2
    local age=$(cat /tmp/age)

    # TODO Parameterize timeout period
    local valid_certificate=1
    if [ ! -z ${age} ] && [ ${age} -lt 7 ]
    then
        valid_certificate=0
    fi

    echo "Certificate validity:" ${valid_certificate} >&2
    return ${valid_certificate}
}

function restore_certificates() {

    local certificate_archive_name="$1"

    echo "Restoring Certificates...." >&2
    if [ -f ${certificate_location}/fullchain1.pem ]; then
        echo "Skipping Restore as files already exist" >&2
    else
        freighter restore /${certificate_archive_name}.tar.gz ${certificate_location} >&2
        echo "Downloaded Certificates" >&2
    fi
    return 0
}

function delete_old_certificates() {

    local backup_archive_name="$1"

    echo "Deleting existing certificates..." >&2
    freighter delete /${backup_archive_name}.tar.gz >&2
    echo "Certificates deleted" >&2

    return 0
}

function generate_new_certificates() {

    echo "Generating new certificates..." >&2
    local domain_name="$1"
    local test_mode="$2"
    local email="$3"
    local additional_cert_options

    if [ ${test_mode} -eq 0 ]
    then
        echo "[WARN] Test mode is on - certificates will not be signed by a valid CA" >&2
        additional_cert_options+="--staging "
    fi

    if [ -z ${email} ];
    then
        additional_cert_options+="--register-unsafely-without-email "
    fi

    start_cert_server

    echo "Starting certbot..." >&2
    mkdir -p /etc/letsencrypt/log
    mkdir -p /etc/letsencrypt/lib
    mkdir -p /etc/letsencrypt/webrootauth

    local cert_options="--webroot-path /etc/letsencrypt/webrootauth -c /app/cert/webroot.ini ${additional_cert_options}"
    echo "Cert Options" ${cert_options} >&2


    certbot certonly ${cert_options} "-d" ${domain_name} "-d"www.${domain_name} >&2
    if [ $? -ne 0 ]
    then
      echo "Error generating certificates" >&2
      kill_cert_server
      exit 1
    fi

    kill_cert_server

    # Copy to canonical location
    mkdir -p ${certificate_location}
    cp /etc/letsencrypt/archive/${domain_name}/privkey1.pem ${certificate_location}
    cp /etc/letsencrypt/archive/${domain_name}/fullchain1.pem ${certificate_location}

    # Return the output dir of where the certs live
    echo "Certificates generated" >&2
    echo ${certificate_location}
}

function start_cert_server() {

    echo "Starting cert server..." >&2
    nginx -c /app/cert/nginx.conf >&2
}

function kill_cert_server() {

    kill $(ps aux | grep '[n]ginx' | awk '{print $2}') >&2
}

function backup_certificates() {

    local backup_archive_name="$1"
    local ssl_dir_name="$2"

    echo "Backing up new certificates..." >&2
    freighter backup ${ssl_dir_name} /${backup_archive_name}.tar.gz >&2
    if [ $? -ne 0 ]
    then
        echo "Error backing up new certs" >&2
        exit 1
    fi
    echo "Certificates backed up" >&2
    return 0
}
