#!/bin/bash

set -e

/etc/init.d/apache2 start
/etc/init.d/nagios start
tailf /usr/local/nagios/var/nagios.log

exec "$@"
