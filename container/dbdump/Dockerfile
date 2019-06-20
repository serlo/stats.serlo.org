FROM alpine
RUN apk update && apk add mysql-client && rm -rf /var/cache/apk/*
RUN mkdir /etc/periodic/midnight
ADD ./scripts/cron.sh /tmp/
ADD ./scripts/run.sh /tmp/run
RUN /bin/chmod a+x /tmp/cron.sh
RUN /bin/chmod a+x /tmp/run
ARG git_revision
ENV GIT_REVISION $git_revision
ARG cron_pattern
ENV CRON_PATTERN $cron_pattern
ARG environment
ENV ENVIRONMENT $environment
CMD ["/tmp/cron.sh"]
