FROM golang:1.12.4-stretch

ENV GO11MODULE=on
ENV GOPATH=/data

WORKDIR /data
COPY . /data

RUN go mod init

CMD ["go", "run", "branch-protections.go"]
