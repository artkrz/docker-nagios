# Source image
FROM debian:stable

# Versions
ENV NAGIOS_VERSION 4.4.13
ENV NAGIOS_PLUGINS_VERSION 2.4.4

# Apt
RUN apt-get update && apt-get install -y \
        apache2 \
        build-essential \
        curl \
        libapache2-mod-php \
        libcrypt-ssleay-perl \
        libgd-dev \
        libwww-perl \
        php \
        php-gd \
        python3 \
        python3-pip \
        unzip \
        wget

# Clean APT cache
RUN apt-get clean

# Create user nad group
RUN useradd nagios && \
    groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagios,nagcmd www-data

# Install Nagios
WORKDIR /tmp
RUN curl https://assets.nagios.com/downloads/nagioscore/releases/nagios-$NAGIOS_VERSION.tar.gz | tar zxv && \
    cd nagios-$NAGIOS_VERSION && \
    ./configure --with-command-group=nagcmd --with-mail=/usr/bin/sendmail --with-httpd-conf=/etc/apache2/conf-available/ && \
RUN make all && \
    make install && \
    make install-init && \
    make install-config && \
    make install-commandmode && \
    make install-webconf && \
RUN cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/ && \
    chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers && \
    /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg && \
RUN a2enconf nagios && \
    a2enmod rewrite cgi &&\
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Install Nagios plugins
RUN curl https://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINS_VERSION.tar.gz | tar zxv && \
    cd nagios-plugins-$NAGIOS_PLUGINS_VERSION && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && \
    make install

# Entry point
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
