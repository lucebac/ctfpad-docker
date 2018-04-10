# CTFPad Docker Container
Dockerized version of CTFPad by StratumAuhuur.

# Setup
`docker pull lucebac/ctfpad`

# Run
It is recommended to use `docker-compose` to run an manage this container. An example compose file is provided below.

# Config
```yml
version: '3'

services:
    ctfpad:
        image: lucebac/ctfpad
        
        ports:
            # ctfpad port
            - "4242:4242"
            # etherpad proxy port
            - "4343:4343"
            
        environment:
            # ctfpad port
            - CTFPAD_PORT=4242
            
            # set both of the following to 'true' if you
            # want to have ctfpad/etherpad use ssl directly
            - CTFPAD_USE_HTTPS=false
            - CTFPAD_PROXY_USE_HTTPS=false

            # default certificates are generated and put to
            # /data/{key,cert}.pem; change this if you e.g.
            # want to use let's encrypt certificates
            - CTFPAD_SSL_KEY_FILE=/data/key.pem
            - CTFPAD_SSL_CERT_FILE=/data/cert.pem

            # authentication key for new signups
            - CTFPAD_AUTHKEY=ctfpad

            # etherpad proxy port
            - ETHERPAD_PORT=4343
            # internal etherpad port; you may not change 
            # this unless you really need to
            - ETHERPAD_INTERNAL_PORT=9001

            # it's strongly recommended to use mysql or 
            # mariadb for etherpad's data storage; 
            # set credentials here
            - MYSQL_HOST=
            - MYSQL_USER=
            - MYSQL_PASSWORD=

        volumes:
            - ./ctfpad_data:/data:z
```
If you want to change the ports CTFPad will listen on, make sure to *both* change the docker ports *and* the environment variables. Otherwise, at least the etherpad istance will not be reachable.

You need to remove and recreate the container if you want to change settings for a running instance if CTFPad. You can use the following snippet:
```sh
docker-compose stop ctfpad
docker-compose rm -f ctfpad
docker-compose up -d --no-deps ctfpad
```