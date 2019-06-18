FROM golang:alpine AS build-env

# Install some dependencies needed to build the project
RUN apk add bash ca-certificates git gcc g++ libc-dev
WORKDIR /app
ADD . /app
ARG git_revision="unknown"
RUN go build -ldflags="-w -s -X main.Revision=$git_revision" -o goapp

FROM alpine
WORKDIR /app
COPY --from=build-env /app/goapp /
ENTRYPOINT [ "/goapp" ]
CMD ["once"]
