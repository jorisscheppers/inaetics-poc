FROM alpine
RUN apk --no-cache add curl
COPY scripts/log-work.bash /scripts/
RUN ["chmod", "+x", "/scripts/log-work.bash"]
CMD /scripts/log-work.bash