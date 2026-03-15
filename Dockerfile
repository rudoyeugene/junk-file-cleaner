FROM alpine:3.23
RUN apk add --update --no-cache coreutils bash
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/bin/bash","/entrypoint.sh"]
