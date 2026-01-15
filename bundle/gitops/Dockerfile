FROM alpine/git

WORKDIR /app
COPY sync.sh /app/sync.sh
RUN chmod +x /app/sync.sh

ENTRYPOINT ["/app/sync.sh"]