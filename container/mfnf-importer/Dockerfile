FROM alpine
RUN apk --update add postgresql-client && rm -rf /var/cache/apk/*
ADD src /tmp/src
ADD ./run.sh /tmp/run
RUN chmod a+x /tmp/run
ARG git_revision
ENV GIT_REVISION $git_revision
CMD ["/tmp/run"]
