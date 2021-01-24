FROM node:12-buster

RUN apt-get install -y jq
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
