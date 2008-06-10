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

<?php
// preparation des tableaux d'options
$version = explode(',',getenv('APPNAME_VERSION'));
?>

# blocage de l'execution en cas de variable non definie
set -u

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
if [[ -f <?php echo getenv('APPNAME_ENV_FILE_PATH') ?> ]]
then
  . <?php echo getenv('APPNAME_ENV_FILE_PATH') ?> 
fi

# ENV specifiques de l'appli
if [[ -f <?php echo getenv('APPNAME_HOME') ?>/env.ksh ]]
then
  . <?php echo getenv('APPNAME_HOME') ?>/env.ksh
fi

# Binaires
HTTPD_HOME=<?php echo getenv('APPNAME_HOME') ?> 
APACHE2CTL="/usr/sbin/apache2ctl"

# Configs
F_LOG_SRV=${HTTPD_HOME}/log/httpd.error.log
F_LOG_LEVEL=<?php if (in_array('dev',$version)) { ?>debug<?php } else { ?>warn<?php } ?> 
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
        echo "Error: httpd pid file does not exist"
        exit ${RC_ERR_NOTSTARTED}
    fi
    pid=`cat ${F_PID}`
    ps -ef | cut -c 10-14,48- | grep "${pid}" > /dev/null
    if [[ ${?} -ne 0 ]]
    then
        echo "Error: httpd process is not running"
        exit ${RC_ERR_NOPROCESS}
    fi
    echo "httpd is listening on <?php echo getenv('APPNAME_APACHE_LISTEN_PORTS'); ?>"
}



#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{                  Traitements               }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--



case ${1} in
	-r | start )
		# demarrage de l'application
		${APACHE2CTL} -f <?php echo getenv('APPNAME_HOME') ?>/etc/httpd.conf -E ${F_LOG_SRV} -e ${F_LOG_LEVEL} -k start
		if [[ ${?} -eq 0 ]]
		then
		    echo "httpd is listening on <?php echo getenv('APPNAME_APACHE_LISTEN_PORTS'); ?>"
		else
		    echo "An error occurred, please consult the logs ${F_LOG_SRV}"
		    exit ${RC_ERR_NOTSTARTED}
		fi
		;;
	-s | stop )
		# arret de l'application
		${APACHE2CTL} -f <?php echo getenv('APPNAME_HOME') ?>/etc/httpd.conf -E ${F_LOG_SRV} -e ${F_LOG_LEVEL} -k stop
		echo "httpd stopped"
		;;
	-u | restart )
	        # redemarrage de l'application
		${APACHE2CTL} -f <?php echo getenv('APPNAME_HOME') ?>/etc/httpd.conf -E ${F_LOG_SRV} -e ${F_LOG_LEVEL} -k restart
		if [[ ${?} -eq 0 ]]
		then
		    echo "httpd is listening on <?php echo getenv('APPNAME_APACHE_LISTEN_PORTS'); ?>"
		else
		    echo "An error occurred, please consult the logs ${F_LOG_SRV}"
		    exit ${RC_ERR_NOTSTARTED}
		fi
		;;
	-c | check )
		# verification du bon fonctionnement de l'application
		running
		;;
	*)
		# parametre invalide
		#'''''''''''''''''''''''

		echo "usage: $0 (-r | -s | -u | -c )"
		cat <<EOF

   -r | start   - start httpd
   -s | stop    - stop httpd
   -u | restart - restart httpd if running by sending a SIGHUP or start if not running
   -c | check   - Test running

EOF

		exit ${RC_ERR_PARAM}
		;;
esac




exit ${RC_OK_TERMINE}
