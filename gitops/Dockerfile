FROM alpine/git:v2.52.0

WORKDIR /app
COPY gitops/sync.sh /app/sync.sh
RUN chmod +x /app/sync.sh

ENTRYPOINT ["/app/sync.sh"]