FROM alpine
RUN apk --update add postgresql-client && rm -rf /var/cache/apk/*
RUN mkdir /etc/periodic/midnight
ADD ./loop.sh /tmp/loop.sh
ADD ./clean.sh /tmp/clean.sh
ADD ./run.sh /tmp/run
RUN chmod a+x /tmp/loop.sh && chmod a+x /tmp/clean.sh && chmod a+x /tmp/run
ARG git_revision
ENV GIT_REVISION $git_revision
ADD ./aggregator.sql /tmp/
ADD ./clean.sql /tmp/
CMD ["/tmp/loop.sh"]
