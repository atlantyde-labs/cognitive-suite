FROM alpine/git

WORKDIR /app

RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app

COPY gitops/sync.sh /app/sync.sh
RUN chmod +x /app/sync.sh && chown -R app:app /app

USER app

ENTRYPOINT ["/app/sync.sh"]
