FROM alpine
RUN apk --update add postgresql-client && rm -rf /var/cache/apk/*
RUN mkdir /etc/periodic/midnight
ADD ./cron.sh /tmp/cron.sh
ADD ./run.sh /tmp/run
ADD ./aggregator.sql /tmp/
RUN chmod a+x /tmp/cron.sh
RUN chmod a+x /tmp/run
ARG git_revision
ENV GIT_REVISION $git_revision
ARG cron_pattern
ENV CRON_PATTERN $cron_pattern
CMD ["/tmp/cron.sh"]
