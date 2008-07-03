#!/bin/sh

set -e

PATH=/bin:/usr/bin:/sbin:/usr/sbin

# INIST
if [[ -f /inist/env/inist.env.ksh ]]
then
  # la machine est correctement installée, tout va bien
  . /inist/env/inist.env.ksh
else
  # dans le cas ou la machine ne contient pas les fichiers d'environement inist
  # on defini en dur ceux dont on aura besoin
  RC_OK_TERMINE=0;       # RC_LIB[0]="Sortie normale."
  RC_ERR_PARAM=103;      # RC_LIB[103]="Erreur dans les parametres d'appel."
  RC_ERR_YETSTARTED=240; # RC_LIB[240]="L'application tourne deja."
  RC_ERR_NOTSTARTED=241; # RC_LIB[241]="L'application ne tourne pas."
  RC_ERR_NOPROCESS=242;  # RC_LIB[242]="Le processus ne tourne pas."
  RC_ERR_PROGRAM=255;    # RC_LIB[255]="Autre erreur."
fi

# Charge les variables utilisateur
if [[ -f <?php echo getenv('APPNAME_ENV_FILE_PATH') ?> ]]
then
  . <?php echo getenv('APPNAME_ENV_FILE_PATH') ?> 
fi

. /lib/lsb/init-functions
. /etc/default/rcS

NAME=tomcat5.5
DESC="Tomcat servlet engine"
CATALINA_HOME=/usr/share/$NAME
DAEMON=$CATALINA_HOME/bin/catalina.sh
CATALINA_OPTS="-Djava.awt.headless=true -Xmx128M -server"
CATALINA_BASE=<?php echo getenv('APPNAME_HOME'); ?> 
TOMCAT5_USER=<?php echo getenv('APPNAME_USER'); ?> 
TOMCAT5_SECURITY=yes
TOMCAT5_SHUTDOWN=30
JAVA_HOME=/usr/lib/jvm/java-1.5.0-sun

test -f $DAEMON || exit 0

# Set java.awt.headless=true if CATALINA_OPTS is not set so the
# Xalan XSL transformer can work without X11 display on JDK 1.4+
# It also looks like the default heap size of 64M is not enough for most cases
# se the maximum heap size is set to 128M
if [ -z "$CATALINA_OPTS" ]; then
	CATALINA_OPTS="-Djava.awt.headless=true -Xmx128M"
fi

# Set the JSP compiler if set in the tomcat5.5.default file
if [ -n "$JSP_COMPILER" ]; then
	CATALINA_OPTS="$CATALINA_OPTS -Dbuild.compiler=$JSP_COMPILER"
fi

# Define other required variables
CATALINA_PID="$CATALINA_BASE/temp/$NAME.pid"
STARTUP_OPTS=""
if [ "$TOMCAT5_SECURITY" = "yes" ]; then
	STARTUP_OPTS="-security"
fi

# Look for Java Secure Sockets Extension (JSSE) JARs
if [ -z "${JSSE_HOME}" -a -r "${JAVA_HOME}/jre/lib/jsse.jar" ]; then
    JSSE_HOME="${JAVA_HOME}/jre/"
fi

export CATALINA_HOME CATALINA_BASE CATALINA_OPTS CATALINA_PID JSSE_HOME JAVA_HOME

case "$1" in
  start)
	if [ -z "$JAVA_HOME" ]; then
		log_failure_msg "Not starting Tomcat: no Java Development Kit found."
		exit 1
	fi

	if [ ! -d "$CATALINA_BASE/conf" ]; then
		log_failure_msg "Not starting Tomcat: invalid CATALINA_BASE specified."
		exit 1
	fi

	log_daemon_msg "Starting $DESC" "$NAME"
	if start-stop-daemon --test --start --pidfile "$CATALINA_PID" \
		--user $TOMCAT5_USER --startas "$JAVA_HOME/bin/java" \
		>/dev/null; then

		# Clean up and set permissions on required files
		rm -rf "$CATALINA_BASE"/temp/* \
			"$CATALINA_BASE/logs/catalina.out"
		mkfifo -m700 "$CATALINA_BASE/logs/catalina.out"
		chown --dereference "$TOMCAT5_USER" "$CATALINA_BASE/conf" \
			"$CATALINA_BASE/conf/tomcat-users.xml" \
			"$CATALINA_BASE/logs" "$CATALINA_BASE/temp" \
			"$CATALINA_BASE/webapps" "$CATALINA_BASE/work" \
			"$CATALINA_BASE/logs/catalina.out" || true

		# Look for rotatelogs/rotatelogs2
		if [ -x /usr/sbin/rotatelogs ]; then
			ROTATELOGS=/usr/sbin/rotatelogs
		else
			ROTATELOGS=/usr/sbin/rotatelogs2
		fi

		# -p preserves the environment (for $JAVA_HOME etc.)
		# -s is required because tomcat5.5's login shell is /bin/false
    $ROTATELOGS "$CATALINA_BASE/logs/catalina_%F.log" 86400	< "$CATALINA_BASE/logs/catalina.out" &
		"$DAEMON" start $STARTUP_OPTS	>> "$CATALINA_BASE/logs/catalina.out" 2>&1
	else
    log_progress_msg "(already running)"
	fi
	log_end_msg 0
	;;
  stop)
	log_daemon_msg "Stopping $DESC" "$NAME"
        if start-stop-daemon --test --start --pidfile "$CATALINA_PID" \
		--user "$TOMCAT5_USER" --startas "$JAVA_HOME/bin/java" \
		>/dev/null; then
		log_progress_msg "(not running)"
	else
    $DAEMON stop >/dev/null 2>&1 || true
		# Fallback to kill the JVM process in case stopping didn't work
		sleep 1
		while ! start-stop-daemon --test --start \
			--pidfile "$CATALINA_PID" --user "$TOMCAT5_USER" \
			--startas "$JAVA_HOME/bin/java" >/dev/null; do
			sleep 1
			log_progress_msg "."
			TOMCAT5_SHUTDOWN=`expr $TOMCAT5_SHUTDOWN - 1` || true
			if [ $TOMCAT5_SHUTDOWN -le 0 ]; then
				log_progress_msg "(killing)"
				start-stop-daemon --stop --signal 9 --oknodo \
					--quiet --pidfile "$CATALINA_PID" \
					--user "$TOMCAT5_USER"
			fi
		done
		rm -f "$CATALINA_PID" "$CATALINA_BASE/logs/catalina.out"
	fi
	log_end_msg 0
	;;
   status)
        if start-stop-daemon --test --start --pidfile "$CATALINA_PID" \
		--user $TOMCAT5_USER --startas "$JAVA_HOME/bin/java" \
		>/dev/null; then

		if [ -f "$CATALINA_PID" ]; then
		    log_success_msg "$DESC is not running, but pid file exists."
		    exit ${RC_ERR_NOTSTARTED}
		else
		    log_success_msg "$DESC is not running."
		    exit ${RC_ERR_NOPROCESS}
		fi
	else
		log_success_msg "$DESC is running with Java pid $CATALINA_PID"
		exit ${RC_OK_TERMINE}
	fi
        ;;
  reload)
	log_failure_msg "Reload is not implemented!"
	exit 3
  	;;
  restart|force-reload)
	$0 stop
	sleep 1
	$0 start
	;;
  *)
	log_success_msg "Usage: $0 {start|stop|restart|force-reload|status}"
	exit 1
	;;
esac

exit ${RC_OK_TERMINE}
