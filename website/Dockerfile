FROM nginxinc/nginx-unprivileged

MAINTAINER Marcelo Pinheiro<contact@marcelopinheiro.co>

EXPOSE 80
USER nginx

ADD styles /usr/share/nginx/html/styles
ADD images /usr/share/nginx/html/images

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html
