FROM nginxinc/nginx-unprivileged

MAINTAINER Marcelo Pinheiro<contact@marcelopinheiro.co>

EXPOSE 80

ADD styles /usr/share/nginx/html/styles
ADD images /usr/share/nginx/html/images

COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html
