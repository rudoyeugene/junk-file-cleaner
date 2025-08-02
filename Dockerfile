FROM alpine:latest
RUN apk add --update --no-cache bash dcron
COPY cleanup_script.sh /
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
RUN chmod +x /cleanup_script.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD []
