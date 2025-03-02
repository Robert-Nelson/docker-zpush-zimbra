FROM php:7.4.33-apache

LABEL MAINTAINER="Robert Nelson <robert-zpush@nelson.house>"

ENV VERSION=2.7
ENV VERSIONFULL=2.7.5
ENV BACKENDVERSION=73
ENV TERM=xterm

ENV ZPUSH_URL=zpush_default

# PHP extensions
RUN docker-php-source extract

RUN apt-get update && apt-get install -y libzip-dev zlib1g && \
	docker-php-ext-configure zip && \
	docker-php-ext-install zip

RUN apt-get install -y \
		libxml2-dev \
		libicu-dev

RUN apt-get install -y libmemcached-dev \
	&& pecl install memcached \
	&& docker-php-ext-enable memcached
	
RUN	docker-php-ext-install -j$(nproc) soap intl

RUN	docker-php-source delete

# Install zpush
RUN mkdir /usr/local/lib/z-push/ /var/log/z-push /var/lib/z-push && \
	chmod 755 /usr/local/lib/z-push/ /var/log/z-push /var/lib/z-push && \
	chown www-data:www-data -R /usr/local/lib/z-push /var/log/z-push /var/lib/z-push
	
RUN curl -L "https://github.com/Z-Hub/Z-Push/archive/refs/tags/$VERSIONFULL.tar.gz" | tar xvz && \
	mv Z-Push-$VERSIONFULL/src/* /usr/local/lib/z-push/ && \
	rm -rf Z-Push-$VERSIONFULL

# Add zimbra backend
RUN cd /usr/local/lib/z-push/backend  && \
	curl -o zpzb-install.sh -L "https://sourceforge.net/projects/zimbrabackend/files/Release${BACKENDVERSION}/zpzb-install.sh/download"  && \
	curl -o zimbra${BACKENDVERSION}.tgz  -L "http://downloads.sourceforge.net/project/zimbrabackend/Release${BACKENDVERSION}/zimbra${BACKENDVERSION}.tgz" 
	
RUN cd /usr/local/lib/z-push/backend &&\
	chmod +x zpzb-install.sh &&\
	sed -i "/chcon[^']*$/d" zpzb-install.sh &&\
	/bin/bash ./zpzb-install.sh $BACKENDVERSION ; exit 0

# Add vhost for zpush
COPY default-vhost.conf /etc/apache2/sites-enabled/000-default.conf

# RUN apt-get install -y less vim net-tools tcpdump

# Expose Apache
EXPOSE 80

COPY ./entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh
ENTRYPOINT ["/bin/bash", "/opt/entrypoint.sh"]
