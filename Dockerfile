# build stage
FROM golang:latest as builder

WORKDIR /go/src/github.com/dgutierrez1287/docker-yum-repo

RUN apt-get update && \
    apt-get upgrade -y libgnutls*

COPY src/*.go .

RUN go mod init logrus && \
    go mod tidy


RUN GOOS=linux go build -x -o repoScanner .

# application image
FROM centos:7
LABEL maintainer="Diego Gutierrez <dgutierrez1287@gmail.com>"

RUN yum -y install epel-release && \
    yum -y update && \
    yum -y install supervisor createrepo yum-utils nginx && rm -rf /var/cache/yum && \
    mkdir -p /repo /home/nginx /var/logs/nginx /logs/repo-scanner /logs/supervisord && \
    touch /var/run/nginx.pid /run/supervisord.pid /var/log/nginx/error.log && \
    chown -R nginx:nginx /repo /home/nginx /var/log /logs /var/run/nginx.pid /run/supervisord.pid

COPY --chmod=0644 supervisord.conf /etc/supervisord.conf

EXPOSE 80
VOLUME /repo /logs

ENV DEBUG=false \
    LINUX_HOST=true \
    SERVE_FILES=true

WORKDIR /home/nginx
USER nginx:nginx
COPY --chmod=0755 --chown=nginx:nginx --from=builder /go/src/github.com/dgutierrez1287/docker-yum-repo/repoScanner /home/nginx/repoScanner

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
