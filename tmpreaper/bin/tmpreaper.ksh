#!/bin/sh
PATH=/usr/sbin:/usr/bin:/sbin:/bin

if ! [ -x /usr/sbin/tmpreaper ]; then
    echo "tmpreaper not found, please install it"
    exit 0
fi

# ! Important !  The "set -f" below prevents the shell from expanding
#                file paths, which is vital for the configuration below to work.
set -f

if [ -s <?php echo getenv('APPNAME_HOME') ?>/etc/tmpreaper.conf ]; then
    . <?php echo getenv('APPNAME_HOME') ?>/etc/tmpreaper.conf
fi

# Verify that these variables are set, and if not, set them to default values
# This will work even if the required lines are not specified in the included
# file above, but the file itself does exist.
TMPREAPER_TIME=${TMPREAPER_TIME:-'7d'}
TMPREAPER_PROTECT_EXTRA=${TMPREAPER_PROTECT_EXTRA:-''}
TMPREAPER_DIRS=${TMPREAPER_DIRS:-'/tmp/.'}

nice -n10 tmpreaper \
  $TMPREAPER_ADDITIONALOPTIONS \
  `for i in $TMPREAPER_PROTECT_EXTRA; do echo --protect "$i"; done` \
  $TMPREAPER_TIME \
  $TMPREAPER_DIRS
