#!/bin/sh

_configure_file() {
    if [ "$#" -ne "3" ]; then
        return
    fi

    local replacement=`echo -ne "$3" | tr -d "\n"`

    sed -i "s|$2|$replacement|" "$1"
}

_apply_envs() {
    local file="$1"
    shift

    local name=""
    local value=""

    while [ $# -ne 0 ]; do
        name="$1"
        eval value=\$$1
        _configure_file "$file" "$name" "$value"
        shift
    done
}

_configure_etherpad() {
    if [ -n "$MYSQL_HOST" -a -n "$MYSQL_USER" -a -n "$MYSQL_PASSWORD" ]; then
        DATABASE_CONNECTION_STRING="
            \"dbType\" : \"mysql\",
            \"dbSettings\" : {
               \"user\"    : \"$MYSQL_USER\",
               \"host\"    : \"$MYSQL_HOST\",
               \"password\": \"$MYSQL_PASSWORD\",
               \"database\": \"store\",
               \"charset\" : \"utf8mb4\"
            },"
    fi

    echo "configuring etherpad..."
    _pwd="/ctfpad/ctfpad/etherpad-lite"
    cp "$_pwd/settings.template.json" "$_pwd/settings.json"
    _apply_envs "$_pwd/settings.json" "DATABASE_CONNECTION_STRING" "ETHERPAD_INTERNAL_PORT"
    chown ctfpad:ctfpad "$_pwd/settings.json"
}

_configure_ctfpad() {
    echo "configuring ctfpad..."
    _pwd="/ctfpad/ctfpad/"
    cp "$_pwd/config.template.json" "$_pwd/config.json"
    _apply_envs "$_pwd/config.json" CTFPAD_PORT ETHERPAD_PORT ETHERPAD_INTERNAL_PORT CTFPAD_SSL_KEY_FILE CTFPAD_SSL_CERT_FILE CTFPAD_AUTHKEY CTFPAD_USE_HTTPS CTFPAD_PROXY_USE_HTTPS
    chown ctfpad:ctfpad "$_pwd/config.json"
}

CTFPAD_PORT=${CTFPAD_PORT:="4242"}
CTFPAD_SSL_KEY_FILE=${CTFPAD_SSL_KEY_FILE:="/data/key.pem"}
CTFPAD_SSL_CERT_FILE=${CTFPAD_SSL_CERT_FILE:="/data/cert.pem"}
CTFPAD_AUTHKEY=${CTFPAD_AUTHKEY:="ctfpad"}
CTFPAD_USE_HTTPS=${CTFPAD_USE_HTTPS:="false"}
CTFPAD_PROXY_USE_HTTPS=${CTFPAD_PROXY_USE_HTTPS:="false"}
DATABASE_CONNECTION_STRING="
    \"dbType\" : \"dirty\",
    \"dbSettings\" : {
        \"filename\" : \"/data/etherpad.sqlite\"
    },"
ETHERPAD_PORT=${ETHERPAD_PORT:="4343"}
ETHERPAD_INTERNAL_PORT=${ETHERPAD_INTERNAL_PORT:="9001"}
MYSQL_HOST=${MYSQL_HOST:=""}
MYSQL_USER=${MYSQL_USER:=""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:=""}

# ensure, /data is there
mkdir -p /data

# create ctfpad sqlite database
if [ ! -f /data/ctfpad.sqlite ]; then
    echo "initializing ctfpad database"
    sqlite3 /data/ctfpad.sqlite < /ctfpad/ctfpad/ctfpad.sql
fi
if [ ! -f /ctfpad/ctfpad/ctfpad.sqlite ]; then
    echo "symlinking ctfpad.sqlite to ctfpad directory"
    rm -f /ctfpad/ctfpad/ctfpad.sqlite
    ln -s /data/ctfpad.sqlite /ctfpad/ctfpad/ctfpad.sqlite
    chown -h ctfpad:ctfpad /ctfpad/ctfpad/ctfpad.sqlite
fi

# create uploads directory
if [ ! -d /ctfpad/ctfpad/uploads ]; then
    echo "creating uploads directory"
    mkdir -p /data/uploads
    rm -f /ctfpad/ctfpad/uploads
    ln -s /data/uploads /ctfpad/ctfpad/uploads
    chown -h ctfpad:ctfpad /ctfpad/ctfpad/uploads
fi

# create ssl cert
if [ ! -f /data/cert.pem ]; then
    echo "Generating SSL certificate"
    openssl genrsa -out /data/key.pem 2>&1 > /dev/null
    openssl req -new -key /data/key.pem -nodes -out /data/csr.pem  -subj "/C=/ST=/L=/O=/OU=/CN=/" 2>&1 > /dev/null
    openssl x509 -req -days 9999 -in /data/csr.pem -signkey /data/key.pem -out /data/cert.pem 2>&1 > /dev/null
    rm /data/csr.pem
fi

# configure etherpad database connection
if [ ! -f /ctfpad/ctfpad/etherpad-lite/settings.json ]; then 
    _configure_etherpad
fi

# configure ctfpad
if [ ! -f /ctfpad/ctfpad/config.json ]; then
    _configure_ctfpad
fi

chown ctfpad:ctfpad -R /data

export NODE_ENV=production

exec "$@"
