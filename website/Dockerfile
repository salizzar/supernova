FROM nginxinc/nginx-unprivileged

MAINTAINER Marcelo Pinheiro<contact@marcelopinheiro.co>

EXPOSE 80

COPY html/index.html /usr/share/nginx/html
COPY html/404.html /usr/share/nginx/html

ADD html/styles /usr/share/nginx/html/styles/
ADD html/images /usr/share/nginx/html/images/

COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
