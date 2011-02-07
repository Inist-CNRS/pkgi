#!/bin/sh
#!/bin/sh

export AWSTATS_ENABLE_CONFIG_DIR=1
export QUERY_STRING="configdir=<?php echo getenv('APPNAME_HOME') ?>/etc/awstats&${QUERY_STRING}"
/usr/lib/cgi-bin/awstats.pl $*