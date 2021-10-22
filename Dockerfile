FROM php:7.3-fpm-alpine

LABEL Maintainer="qiuapeng@vchangyi.com"

ENV XLSWRITER_VERSION=1.3.7

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装常用服务
RUN apk update \
    && apk add openssh tzdata supervisor nginx wget bash openssl \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && mkdir -p /run/nginx

# 安装ssh
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config \
    && ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key \
    && ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key \
    && echo "root:changyi" | chpasswd

# 安装依赖库
RUN apk add --no-cache libstdc++ wget openssl bash supervisor nginx \
    libmcrypt-dev libzip-dev libpng-dev libc-dev zlib-dev librdkafka-dev \
    freetype-dev libjpeg-turbo-dev libpng-dev

RUN apk add --no-cache --virtual .build-deps autoconf automake make g++ gcc \
    libtool dpkg-dev dpkg pkgconf file re2c pcre-dev php7-dev php7-pear openssl-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    # 安装php常用扩展
    && docker-php-ext-install -j$(nproc) gd bcmath opcache mysqli pdo pdo_mysql sockets zip \
    && wget http://pecl.php.net/get/redis-5.3.4.tgz \
    && wget http://pecl.php.net/get/mcrypt-1.0.4.tgz \
    && wget http://pecl.php.net/get/mongodb-1.10.0.tgz \
    && wget http://pecl.php.net/get/rdkafka-5.0.0.tgz \
    # Extension redis mcrypt mongodb rdkafka
    && pecl install redis-5.3.4.tgz mcrypt-1.0.4.tgz mongodb-1.10.0.tgz rdkafka-5.0.0.tgz \
    && rm -rf redis-5.3.4.tgz mcrypt-1.0.4.tgz mongodb-1.10.0.tgz rdkafka-5.0.0.tgz \
    && docker-php-ext-enable redis mcrypt mongodb rdkafka \
    # 安装 Composer
    && wget https://mirrors.cloud.tencent.com/composer/composer.phar \
    && mv composer.phar  /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    # 安装 Xlswriter
    && wget http://pecl.php.net/get/xlswriter-${XLSWRITER_VERSION}.tgz -O xlswriter.tar.gz \
    && mkdir -p xlswriter \
    && tar -xf xlswriter.tar.gz -C xlswriter --strip-components=1 \
    && rm xlswriter.tar.gz \
    && cd xlswriter \
    && phpize && ./configure --enable-reader && make && make install \
    && docker-php-ext-enable xlswriter \
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