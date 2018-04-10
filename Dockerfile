FROM alpine:3.7

LABEL maintainer="lucebac <docker@lucebac.net>"

RUN apk add -U --no-cache curl unzip nodejs nodejs-npm sqlite openssl git python \
    && adduser -D ctfpad \
    && mkdir /ctfpad && chown ctfpad:ctfpad /ctfpad

WORKDIR /ctfpad

# setup ctfpad
RUN cd /ctfpad \
    && git clone https://github.com/StratumAuhuur/CTFPad ctfpad \
    && cd ctfpad \ 
    && npm install

# setup underlying etherpad
RUN cd /ctfpad/ctfpad \
    && git clone https://github.com/ether/etherpad-lite.git etherpad-lite \
    && ./etherpad-lite/bin/installDeps.sh \
    && rm etherpad-lite/settings.json

# add config files
ADD config.template.json /ctfpad/ctfpad/config.template.json
ADD settings.template.json /ctfpad/ctfpad/etherpad-lite/settings.template.json

WORKDIR /ctfpad/ctfpad

RUN chown ctfpad:ctfpad -R /ctfpad

VOLUME ["/data"]

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 4242 4343
CMD ["su", "ctfpad", "-c", "node main.js"]
