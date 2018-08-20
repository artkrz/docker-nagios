# Source image
FROM debian:stable

# Versions
ENV NAGIOS_VERSION 4.4.2
ENV NAGIOS_PLUGINS_VERSION 2.2.1

# Apt
RUN apt-get update && apt-get install -y \
        apache2 \
        apache2-mod-php7.0 \
        build-essential \
        curl \
        libcrypt-ssleay-perl \
        libgd-dev \
        libwww-perl \
        php \
        php-gd \
        python \
        python-pip \
        unzip \
        wget

# Clean APT cache
RUN apt-get clean

# Install PIP packages
RUN pip install requests simplejson

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
    make all && \
    make install && \
    make install-init && \
    make install-config && \
    make install-commandmode && \
    make install-webconf && \
    cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/ && \
    chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers && \
    /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg && \
    a2enconf nagios && \
    a2enmod rewrite cgi &&\
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Install Nagios plugins
RUN curl https://nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGINS_VERSION.tar.gz | tar zxv && \
    cd nagios-plugins-$NAGIOS_PLUGINS_VERSION && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && \
    make install

# Install Slack integration plugin
RUN wget https://raw.github.com/tinyspeck/services-examples/master/nagios.pl && mv nagios.pl /usr/local/nagios/libexec/slack_nagios.pl && chmod 755 /usr/local/nagios/libexec/slack_nagios.pl

# Entry point
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
