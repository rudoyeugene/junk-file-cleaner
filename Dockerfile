FROM alpine:latest
RUN apk add --update --no-cache bash
COPY cleaner.sh /
RUN chmod +x /cleaner.sh
CMD ["/cleaner.sh"]
