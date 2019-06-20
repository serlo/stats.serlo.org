FROM golang:alpine AS build-env

# Install some dependencies needed to build the project
RUN apk add ca-certificates git gcc g++ libc-dev && rm -rf /var/cache/apk/*
WORKDIR /app
ADD . /app
ARG git_revision
RUN go build -ldflags="-w -s -X main.Revision=$git_revision" -o goapp

FROM alpine
WORKDIR /app
COPY --from=build-env /app/goapp .
RUN chmod a+x ./goapp
COPY ./run.sh /app/run
RUN chmod a+x /app/run
COPY ./cron.sh /app/cron.sh
RUN chmod a+x /app/cron.sh
ARG git_revision
ENV GIT_REVISION $git_revision
ARG cron_pattern
ENV CRON_PATTERN $cron_pattern
CMD ["/app/cron.sh"]
