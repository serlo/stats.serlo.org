FROM golang:alpine AS build-env

# Install some dependencies needed to build the project
RUN apk add bash ca-certificates git gcc g++ libc-dev
WORKDIR /app
ADD . /app
ARG git_revision="unknown"
RUN go build -ldflags="-w -s -X main.Revision=$git_revision" -o goapp

FROM alpine
WORKDIR /app
COPY --from=build-env /app/goapp /app/
COPY ./run.sh /tmp/run
RUN chmod a+x /tmp/run
COPY ./cron.sh /tmp/cron.sh
RUN chmod a+x /tmp/cron.sh
ARG cron_pattern
ENV CRON_PATTERN $cron_pattern
CMD ["/tmp/cron.sh"]
