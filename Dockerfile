FROM alpine:3.21
RUN apk add --update --no-cache bash
COPY cleaner.sh /
RUN chmod +x /cleaner.sh
CMD ["/cleaner.sh"]
