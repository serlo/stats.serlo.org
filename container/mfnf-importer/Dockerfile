FROM alpine
RUN apk --update add postgresql-client python3 py3-requests python3-dev py3-pip build-base && rm -rf /var/cache/apk/*
RUN pip3 install --upgrade pip
RUN pip3 install pandas
ADD src /tmp/src
ADD ./run.sh /tmp/run
RUN chmod a+x /tmp/run
ARG git_revision
ENV GIT_REVISION $git_revision
CMD ["/tmp/run"]
