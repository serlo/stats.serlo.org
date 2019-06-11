FROM golang:alpine
# Install some dependencies needed to build the project
RUN apk add bash ca-certificates git gcc g++ libc-dev
WORKDIR /app
ADD . /app
RUN cd /app && go build -o goapp
ENTRYPOINT [ "/app/goapp" ]
CMD ["once"]
