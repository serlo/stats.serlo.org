FROM alpine
RUN apk update && apk add mysql-client
ADD ./run.sh /tmp/run.sh
RUN apk update
RUN apk upgrade
RUN apk add bash
RUN chmod +x /tmp/run.sh
ARG git_revision
ENV GIT_REVISION=$git_revision

ENTRYPOINT [ "/bin/bash", "/tmp/run.sh" ]