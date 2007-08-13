#---------------------------------------------------------------------------#
#----------                                                       ----------#
#----------     Lancement d'Apache et Mysql                       ----------# 
#----------                                                       ----------#
#----------             2005     I.N.I.S.T                        ----------#
#----------                                                       ----------#
#---------------------------------------------------------------------------#
       

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-
#=-=-                                                         =-=-
#=-=-   Environnement de l'application                        =-=-
#=-=-                                                         =-=-
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-

# blocage de l'execution en cas de variable non definie
#''''''''''''''''''''''''''''''''''''''''''''''''''''''
set -u

#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{ Chargement des environnements              }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--

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
  RC_ERR_BREAK=101;      # RC_LIB[101]="Sortie par interruption."
fi


#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{     Definitions Variables Erreur           }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--

if [[ -f /inist/env/inist.rc.ksh ]]
then
  . /inist/env/inist.rc.ksh
fi

#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{          Controles  Divers                 }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--


# Traitement des interruptions
trap 'RC=${?}; trap "" ERR INT; print >&2 Erreur ${RC} ligne ${LINENO} dans ${0}; exit ${RC}' ERR
trap 'trap "" INT; print >&2 'Interruption' ;exit ${RC_ERR_BREAK}' INT



# Controle du nombre de parametres d appel
#''
if [[ ${#} -ne 1 ]]
then
	exit ${RC_ERR_PARAM}
fi


#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--
#	--{                                            }--
#	--{                  Traitements               }--
#	--{                                            }--
#	--{--{--{--{--{--{--{--{--}--}--}--}--}--}--}--}--


HTTP_KSH=<?php echo getenv('APPNAME_HOME') ?>/bin/httpd.ksh
MYSQL_KSH=<?php echo getenv('APPNAME_HOME') ?>/bin/mysql.ksh


case ${1} in
	-r )
		# demarrage de l'application : serveur + base
		
		# Serveur Apache
		${HTTP_KSH} -r
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_YETSTARTED} ]]
		then
			exit ${?}
		fi
		
		# Base Mysql
		${MYSQL_KSH} -r
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_YETSTARTED} ]]
		then
			exit ${?}
		fi
		
		;;
	-s ) 
		# arret de l'application : serveur + base
		
		# Serveur Apache
		${HTTP_KSH} -s
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_NOTSTARTED}  &&  ${?} -ne ${RC_ERR_NOPROCESS} ]]
		then
			exit ${?}
		fi
		
		# Base Mysql
		${MYSQL_KSH} -s
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_NOTSTARTED}  &&  ${?} -ne ${RC_ERR_NOPROCESS} ]]
		then   
			exit ${?}
		fi
		
		;;
		
	-u ) 
		# redemarrage de l'application : serveur + base
		
		# Serveur Apache
		${HTTP_KSH} -u
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_PROGRAM} ]]
		then
			exit ${?}
		fi
		
		# Base Mysql
		${MYSQL_KSH} -u
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_PROGRAM} ]]
		then
			exit ${?}
		fi
		
		;;
		
	-a ) 
		# verification du bon fonctionnement du serveur Apache
		
		${HTTP_KSH} -c
		exit ${?}
	
		;;
	 -m ) 
		# verification du bon fonctionnement du serveur mysql
		
		${MYSQL_KSH} -c
		exit ${?}
		
		;;
	
	*) 
		# parametre invalide
		
			echo "usage: $0 ( -r | -s | -u | -a | -m )"
			cat <<EOF

   -r   - start Apache + mysql
   -s   - stop Apache + mysql
   -u   - restart Apache + mysql if running by sending a SIGHUP or start if not running
   -a   - Test running Apache
   -m   - Test running mysql
   
EOF
		exit ${RC_ERR_PARAM}
		;;
esac

exit ${RC_OK_TERMINE}
