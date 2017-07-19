#!/usr/bin/env bash

source /app/cert/certificate_service.sh

project_name=default
test_mode=1

function main (){

    while getopts ':d:s:n:e:h:t' option
    do
        case ${option} in
            d  ) domain_name=$OPTARG;;
            s  ) service_address=$OPTARG;;
            n  ) project_name=$OPTARG;;
            e  ) email=$OPTARG;;
            t  ) test_mode=0;;
            h  ) usage; exit;;
            \? ) echo "Unknown option: -$OPTARG" >&2; usage; exit 1;;
            :  ) echo "Missing option argument for -$OPTARG" >&2; usage; exit 1;;
        esac
    done

    if [ -z ${domain_name} ] || [ -z ${service_address} ];
    then
        echo "Not enough arguments supplied" >&2
        usage
        exit 1
    fi

    echo "domain name(s): ${domain_name}"
    echo "service address: ${service_address}"
    echo "project_name: ${project_name}"
    echo "test mode: ${test_mode}"
    echo "email: ${email}"


    templatise_files ${domain_name} ${service_address} ${email}

    if has_configured_remote_store;
    then
        prepare_certificates_with_remote_store ${domain_name} ${project_name} ${test_mode} ${email}
    else
        local status=$(generate_new_certificates ${domain_name} ${test_mode} ${email})
        if [ ! ${status} ]; then exit 1; fi
    fi

    echo "Configuration complete, starting main proxy process..." >&2
    nginx -c /app/proxy/nginx.conf -g "daemon off;"
}

function templatise_files() {

    local domain_name="$1"
    local service_address="$2"
    local email="$3"

    cp /app/cert/webroot.ini.tpl /app/cert/webroot.ini
    if [ ! -z ${email} ];
    then
        echo "email = ${email}" | cat >> /app/cert/webroot.ini
    fi

    sed -e 's%${domain_name}%'"${domain_name}"'%' \
        -e 's%${service_address}%'"${service_address}"'%' \
        /app/proxy/nginx.conf.tpl > /app/proxy/nginx.conf
}

function has_configured_remote_store() {

    if [ ! -z ${FREIGHTER_PROVIDER} ] && [ ! -z ${FREIGHTER_TOKEN} ];
    then
         echo "Remote Store configuration detected - certificates will be reused and backed up where possible" >&2
         return 0;
    fi

    return 1;
}

function prepare_certificates_with_remote_store(){

    local domain_name="$1"
    local project_name="$2"
    local test_mode="$3"
    local email="$4"
    local certificate_archive_name="ssl-${project_name}"

    if $(is_certificate_valid ${certificate_archive_name})
    then
        restore_certificates ${certificate_archive_name}
    else
        delete_old_certificates ${certificate_archive_name}
        local ssl_dir_name=$(generate_new_certificates ${domain_name} ${test_mode} ${email})
        echo "Returned ssl_dir:" ${ssl_dir_name} >&2
        if [ ! ${ssl_dir_name} ]; then exit 1; fi
        backup_certificates ${certificate_archive_name} ${ssl_dir_name}
    fi
}

function usage() {
cat <<EOF

Usage: pontem [options]

Mandatory Arguments:
-d |                  A domain name e.g. [foo.com]
-s |                  A downstream service address e.g. [http://178.0.13.23:80] OR [https://foobar:443]

Optional Arguments:
-n |                  A project name - Default: default
-e |                  An email address (for certificate expiry notifications)
-t |                  Enable test mode (uses LetsEncrypt staging environment to generate certificates to prevent rate limit breaches)
-h |                  Show usage

EOF
}

main "$@"
