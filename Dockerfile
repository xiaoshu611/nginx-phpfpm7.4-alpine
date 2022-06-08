FROM php:7.3-fpm-alpine

LABEL Maintainer="qiuapeng@vchangyi.com"

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装常用服务
RUN apk update \
    && apk add openssh tzdata supervisor nginx wget bash openssl \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && mkdir -p /run/nginx

# 安装依赖库
RUN apk add --no-cache libstdc++ libzip-dev libpng-dev zlib-dev freetype-dev libjpeg libjpeg-turbo-dev

RUN apk add --no-cache --virtual .build-deps \
    # 安装php常用扩展
    && install-php-extensions gd bcmath opcache mysqli pdo_mysql sockets zip ssh2 redis mcrypt mongodb rdkafka xlswriter @composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    # 删除系统扩展
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && php -m

# 下载gocron客户端
RUN wget https://wesociastg.blob.core.chinacloudapi.cn/wesocial-uat/gocron-node-v1.5.3-linux-amd64.tar.gz \
    && tar -zxvf gocron-node-v1.5.3-linux-amd64.tar.gz && rm -rf gocron-node-v1.5.3-linux-amd64.tar.gz \
    && mv gocron-node-linux-amd64/gocron-node /usr/bin/gocron-node && rm -rf /var/www/html/*

COPY config/supervisord/supervisord.conf /etc/supervisord.conf
COPY config/supervisord/conf.d/* /etc/supervisor/conf.d/
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY config/php/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY config/php/php.ini /usr/local/etc/php/

COPY index.php /usr/share/nginx/html/src/public/

WORKDIR /usr/share/nginx/html/

EXPOSE 22 80 5921

ENTRYPOINT ["supervisord","-c","/etc/supervisord.conf"]
