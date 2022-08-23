FROM alpine:latest
MAINTAINER Marcelo Pinheiro<contact@marcelopinheiro.co>

EXPOSE 80

RUN apk update && \
    apk upgrade && \
    apk add nginx

ADD styles /usr/share/nginx/html/styles
ADD images /usr/share/nginx/html/images
COPY index.html /usr/share/nginx/html
