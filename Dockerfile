# Use prebuilt base image (Dockerfile.baseimage) to save some time (~45 secs to build)
FROM tmigone/versionist:latest

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
