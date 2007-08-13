#!/bin/ksh

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#-----                                                                 -----
#-----                                                                 -----
#-----    Lancement d'un serveur HTTP                                  -----
#-----                                                                 -----
#-----                                                                 -----
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------


# blocage de l'execution en cas de variable non definie
set -u

<?php if ( getenv('APPNAME_APACHE_HTTP_PORT') == 0 && getenv('APPNAME_APACHE_HTTPS_PORT') == 0) { ?>
exit ${RC_OK_TERMINE}
<?php die(); } ?>

# on met a zero l'environement
env -i

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

# SG: si LANG n'est pas mis a "C" alors gettext et ldap ne fonctinnent pas!
export LANG=C

# ORACLE : pour un exemple de chaine de connexion : http://wiki.intra.inist.fr/faq/php5-oci8
export ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/client
export LD_LIBRARY_PATH=$ORACLE_HOME/lib


# ENV generiques de l'appli (port http, port mysql ...)
if [[ -f <?php echo getenv('APPNAME_HOME') ?>/src.env.ksh ]]
then
  . <?php echo getenv('APPNAME_HOME') ?>/src.env.ksh
fi

# ENV specifiques de l'appli
if [[ -f <?php echo getenv('APPNAME_HOME') ?>/env.ksh ]]
then
  . <?php echo getenv('APPNAME_HOME') ?>/env.ksh
fi

# HOME
HTTPD_HOME=<?php echo getenv('APPNAME_HOME') ?>

# Executable
HTTPD_BIN="/usr/sbin/apache2"

# Configs
<?php if (getenv('APPNAME_APACHE_HTTP_PORT') != 0) { ?>
F_LOG_SRV=${HTTPD_HOME}/log/<?php echo getenv('APPNAME_APACHE_HTTP_PORT'); ?>-error.log
<?php } else if (getenv('APPNAME_APACHE_HTTPS_PORT') != 0) { ?>
F_LOG_SRV=${HTTPD_HOME}/log/<?php echo getenv('APPNAME_APACHE_HTTPS_PORT'); ?>-error.log
<?php } else { ?>
F_LOG_SRV=${HTTPD_HOME}/log/httpd-error.log
<?php } ?>
F_CNF=${HTTPD_HOME}/etc/httpd.conf
F_PID=${HTTPD_HOME}/var/httpd.pid


#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{          Controles  Divers                 }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--


# Nombre de parametres
if [[ ${#} -ne 1 ]]
then
	exit ${RC_ERR_PARAM}
fi

# preparer le traitement de fin de programme
L_DEL=""
trap 'trap "" INT; rm -f ${L_DEL}' EXIT


#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{     Definitions Fonctions                  }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--


function running {
	if [[ ! -f ${F_PID} ]]
	then
    echo "ERROR: httpd pid file does not exist"
		exit ${RC_ERR_NOTSTARTED}
	fi
	pid=`cat ${F_PID}`
	ps -ef | cut -c 10-14,48- | grep "${pid}" > /dev/null
	if [[ ${?} -ne 0 ]]
	then
    echo "ERROR : httpd process is not running"
		exit ${RC_ERR_NOPROCESS}
	fi
  echo "httpd is listening on <?php
$ports = array();
if (getenv('APPNAME_APACHE_HTTP_PORT')!= 0)  $ports[] = getenv('APPNAME_APACHE_HTTP_PORT').'(http)';
if (getenv('APPNAME_APACHE_HTTPS_PORT')!= 0) $ports[] = 'https='.getenv('APPNAME_APACHE_HTTPS_PORT').'(https)';
echo implode(', ', $ports);
?>"
}



#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{                  Traitements               }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--



case ${1} in
	-r | start )
		# demarrage de l'application
		if [[ -f ${F_PID} ]]
		then
			kill -s 0 `cat ${F_PID}` 2> /dev/null
			if [[ ${?} -eq 0 ]]
			then
        echo "ERROR : httpd is yet started"
				exit ${RC_ERR_YETSTARTED}
			fi
		fi
		${HTTPD_BIN} -f ${F_CNF} 2>| ${F_LOG_SRV} &
		sleep 2
		running
		;;
	-s | stop )
		# arret de l'application
		if [[ ! -f ${F_PID} ]]
		then
      echo "ERROR : cannot stop httpd because its pid file doesn't exist"
			exit ${RC_ERR_NOTSTARTED}
		fi
		pid=`cat ${F_PID}`
		kill -s TERM ${pid} 2> /dev/null
		if [[ ${?} -ne 0 ]]
		then
      echo "ERROR : cannot stop httpd because its process doesn't exist"
			exit ${RC_ERR_NOPROCESS}
		else
			kill -s TERM ${pid} 2> /dev/null
  echo "Stopping httpd on <?php
$ports = array();
if (getenv('APPNAME_APACHE_HTTP_PORT')!= 0)  $ports[] = 'http='.getenv('APPNAME_APACHE_HTTP_PORT');
if (getenv('APPNAME_APACHE_HTTPS_PORT')!= 0) $ports[] = 'https='.getenv('APPNAME_APACHE_HTTPS_PORT');
echo implode(', ', $ports);
?>"
      sleep 2
		fi
		;;
	-u )
		# redemarrage de l'application
    <?php echo getenv('APPNAME_HOME') ?>/bin/httpd.ksh -s
    <?php echo getenv('APPNAME_HOME') ?>/bin/httpd.ksh -r
		;;
	-c )
		# verification du bon fonctionnement de l'application
		running
		;;
	*)
		# parametre invalide
		#'''''''''''''''''''''''

			echo "usage: $0 (-r | -s | -u | -c )"
			cat <<EOF

   -r | start  - start httpd
   -s | stop   - stop httpd
   -u          - restart httpd if running by sending a SIGHUP or start if not running
   -c          - Test running

EOF

		exit ${RC_ERR_PARAM}
		;;
esac




exit ${RC_OK_TERMINE}
