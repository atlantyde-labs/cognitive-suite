FROM alpine/git

WORKDIR /app
COPY gitops/sync.sh /app/sync.sh
RUN chmod +x /app/sync.sh

ENTRYPOINT ["/app/sync.sh"]