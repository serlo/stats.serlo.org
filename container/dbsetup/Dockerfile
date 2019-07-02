FROM alpine
RUN apk update && apk add mysql-client unzip && rm -rf /var/cache/apk/*
ADD ./cron.sh /tmp/
ADD ./run.sh /tmp/run
RUN /bin/chmod +x /tmp/cron.sh && /bin/chmod +x /tmp/run
ARG git_revision
ENV GIT_REVISION=$git_revision
ARG cron_pattern
ENV CRON_PATTERN $cron_pattern
CMD ["/tmp/cron.sh"]
