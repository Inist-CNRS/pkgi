#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#-----                                                                 -----
#-----                                                                 -----
#-----    Lancement d'une base MYSQL                                   -----
#-----                                                                 -----
#-----                                                                 -----
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

# blocage de l'execution en cas de variable non definie
set -u

<?php if ( getenv('APPNAME_MYSQL_PORT') == 0) { ?>
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

MYSQLD_HOME=/usr 
MYSQLD_BIN=${MYSQLD_HOME}/bin/mysqld_safe

# Configs
F_PID=<?php echo getenv('APPNAME_HOME') ?>/var/mysql.pid
D_DAT=<?php echo getenv('APPNAME_HOME') ?>/var/mysql
F_CNF=<?php echo getenv('APPNAME_HOME') ?>/etc/my.cnf
F_SOK=<?php echo getenv('APPNAME_HOME') ?>/var/run/mysql.socket
F_LOG=<?php echo getenv('APPNAME_HOME') ?>/log/mysql.log
D_BAS=${MYSQLD_HOME}

#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{          Controles  Divers                 }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--


# Nombre de parametres
if [[ ${#} -eq 0 ]]
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
    echo "ERROR : cannot stop mysql because its pid file doesn't exist"
		exit ${RC_ERR_NOTSTARTED}
	fi
	pid=`cat ${F_PID}`
	ps -ef | cut -c 10-14,48- | grep ${pid} | grep  mysql > /dev/null
	if [[ ${?} -ne 0 ]]
	then
    echo "ERROR : mysql process is not running"
		exit ${RC_ERR_NOPROCESS}
	fi
  echo "mysql is listening on <?php
$ports = array();
if (getenv('APPNAME_MYSQL_PORT')!= 0)  $ports[] = getenv('APPNAME_MYSQL_PORT');
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
        echo "ERROR : mysql is yet started"
				exit ${RC_ERR_YETSTARTED}
			fi
		fi
		${MYSQLD_BIN} --defaults-file=${F_CNF} --basedir=${D_BAS} --language=french &
		sleep 2
		running
		;;
	-s | stop )
		# arret de l'application
		if [[ ! -f ${F_PID} ]]
		then
      echo "ERROR : cannot stop mysql because its pid file doesn't exist"
			exit ${RC_ERR_NOTSTARTED}
		fi
		pid=`cat ${F_PID}`
		kill -s TERM ${pid} 2> /dev/null
		if [[ ${?} -ne 0 ]]
		then
      echo "ERROR : cannot stop mysql because its process doesn't exist"
			exit ${RC_ERR_NOPROCESS}
		else
			kill -s TERM ${pid} 2> /dev/null
  echo "Stopping mysql on <?php
$ports = array();
if (getenv('APPNAME_MYSQL_PORT')!= 0)  $ports[] = 'http='.getenv('APPNAME_MYSQL_PORT');
echo implode(', ', $ports);
?>"
      sleep 3
		fi
		;;
	-u )
		# redemarrage de l'application
    <?php echo getenv('APPNAME_HOME') ?>/bin/mysql.ksh -s
    <?php echo getenv('APPNAME_HOME') ?>/bin/mysql.ksh -r
		;;
	-c )
		# Verification du bon fonctionnement de l'application
		running
		;;
	-q | sql )
	    	# Se connceter à la base
	    	${MYSQLD_HOME}/bin/mysql --defaults-file=${F_CNF} 
	    ;;
  -mr | makeroot )
				if [[ ${#} -lt 2 ]]
            then
                echo "Error: missing parameter (hostname)."
                echo "Example: bin/mysql.ksh -mr gully.ads.intra.inist.fr"
                exit ${RC_ERR_PARAM}
            fi
            MRHOST=${2}
            cat <?php echo getenv('APPNAME_HOME') ?>/etc/mysql-makeroot.sql | sed s/{HOST}/${MRHOST}/g | ${MYSQLD_HOME}/bin/mysql --defaults-file=${F_CNF} mysql
            echo "Now ${MRHOST} is allowed to connect as root to the database (using phpmyadmin for example)"
            echo "Query was :"
            cat <?php echo getenv('APPNAME_HOME') ?>/etc/mysql-makeroot.sql | sed s/{HOST}/${MRHOST}/g
            ;;
	-cmd | cmd )
        	shift 1
	    	${MYSQLD_HOME}/bin/mysql --defaults-file=${F_CNF} $* 
	    ;;
	-d | dump )
        	shift 1
	    	${MYSQLD_HOME}/bin/mysqldump --defaults-file=${F_CNF} $* 
	    ;;
    	-t | copyto )
            # Copie des bases sur un autre serveur
            if [[ ${#} -lt 2 ]]
            then
                exit ${RC_ERR_PARAM}
            fi
			if [[ ${#} -eq 3 ]]
            then
				BASES="--databases ${3}"
			else
				BASES="--all-databases"
            fi
            REMOTE_HOST=`echo "${2}" | cut -d":" -f 1 `
            REMOTE_PORT=`echo "${2}"  | cut -d":" -f 2 `
            if [[ "${REMOTE_PORT}" = "${REMOTE_HOST}" ]]
            then
                REMOTE_PORT="3306"
            fi
            ${MYSQLD_HOME}/bin/mysql --user=root --password= --host=${REMOTE_HOST} --port=${REMOTE_PORT} -e "exit" 
            if [[ ${?} -ne 0 ]]
            then
                exit ${RC_ERR_NOPROCESS}
            else
                ${MYSQLD_HOME}/bin/mysqldump --opt ${BASES} | ${MYSQLD_HOME}/bin/mysql --user=root --password= --host=${REMOTE_HOST}  --port=${REMOTE_PORT}
            fi
        ;;
	-f | copyfrom )
            # Récupération des bases d'un autre serveur
			if [[ ${#} -lt 2 ]]
            then
                exit ${RC_ERR_PARAM}
            fi
			if [[ ${#} -eq 3 ]]
            then
				BASES="--databases ${3}"
			else
				BASES="--all-databases"
            fi
            REMOTE_HOST=`echo "${2}" | cut -d":" -f 1 `
            REMOTE_PORT=`echo "${2}"  | cut -d":" -f 2 `
            if [[ "${REMOTE_PORT}" = "${REMOTE_HOST}" ]]
            then
                REMOTE_PORT="3306"
            fi
            ${MYSQLD_HOME}/bin/mysql --user=root --password= --host=${REMOTE_HOST} --port=${REMOTE_PORT} -e "exit" 
            if [[ ${?} -ne 0 ]]
            then
                exit ${RC_ERR_NOPROCESS}
            else
                ${MYSQLD_HOME}/bin/mysqldump --user=root --password= --host=${REMOTE_HOST} --port=${REMOTE_PORT} --opt ${BASES} | ${MYSQLD_HOME}/bin/mysql --defaults-file=${F_CNF} 
            fi
        ;;
	-i | init )
			# Initialisation de la base
			export PATH=${PATH}:${MYSQLD_HOME}/bin
			${MYSQLD_HOME}/bin/mysql_install_db  --no-defaults --basedir=${D_BAS} --datadir=${D_DAT} >/dev/null
		;;
	*)
		# parametre invalide
		#'''''''''''''''''''''''

			echo "usage: $0 (-r | -s | -u | -c )"
			cat <<EOF

   -r | start     - start mysql
   -s | stop      - stop mysql
   -u             - restart mysql if running by sending a SIGHUP or start if not running
   -c             - Verification du bon fonctionnement du serveur
   -cmd           - Permet de lancer la commande mysql (placez vos parametres a la suite)
   -d | dump      - Permet de lancer la commande mysqldump (placez vos parametres a la suite)
   -mr | makeroot - Permet de donner les droits de connexion a un host passe en parametre
   -q | sql       - Se connceter à la base
   -t | copyto    - Copie d'une ou de toutes les bases sur un autre serveur 
   -f | copyfrom  - Récupération d'une ou de toutes les bases d'un autre serveur
   -i | init      - Initialisation de la base
   -d | dump      - execute mysqldump (permet de sauvegarder un dump de la base facilement)

EOF

		exit ${RC_ERR_PARAM}
		;;
esac




exit ${RC_OK_TERMINE}