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


case ${1} in
	-r | start )
<?php
  $dstart_list = unserialize(getenv('APPNAME_DSTART_LIST'));
  foreach($dstart_list as $module => $cmd) {
?>
		# Démarrage de <?php echo $module; ?> 
                <?php if (!is_array($cmd)) $cmd = array($cmd); ?>
                <?php foreach( $cmd as $c ) { ?>
                <?php echo getenv('APPNAME_HOME'); ?>/<?php echo $c; ?> 
                <?php } ?>
		if [[ ${?} -ne ${RC_OK_TERMINE} && ${?} -ne ${RC_ERR_YETSTARTED} ]]
		then
			exit ${?}
		fi

<?php } ?>		
		;;

	-s | stop ) 
<?php
  $dstop_list = unserialize(getenv('APPNAME_DSTOP_LIST'));
  foreach($dstop_list as $module => $cmd) {
?>
		# Arret de <?php echo $module; ?> 
                <?php if (!is_array($cmd)) $cmd = array($cmd); ?>
                <?php foreach( $cmd as $c ) { ?>
                <?php echo getenv('APPNAME_HOME'); ?>/<?php echo $c; ?> 
                RCODE=${?}
		if [[ ${RCODE} -ne ${RC_OK_TERMINE} && ${RCODE} -ne ${RC_ERR_NOTSTARTED}  &&  ${RCODE} -ne ${RC_ERR_NOPROCESS} ]]
		then
			exit ${RCODE}
		fi
                <?php } ?>

<?php } ?>
		;;
		
	-u | restart ) 
<?php
  $drestart_list = unserialize(getenv('APPNAME_DRESTART_LIST'));
  foreach($drestart_list as $module => $cmd) {
?>
		# Redemarrage de <?php echo $module; ?> 
                <?php if (!is_array($cmd)) $cmd = array($cmd); ?>
                <?php foreach( $cmd as $c ) { ?>
                <?php echo getenv('APPNAME_HOME'); ?>/<?php echo $c; ?> 
                RCODE=${?}
		if [[ ${RCODE} -ne ${RC_OK_TERMINE} && ${RCODE} -ne ${RC_ERR_PROGRAM} ]]
		then
			exit ${RCODE}
		fi
                <?php } ?>
<?php } ?>
	  ;;

	-c | check | status ) 
<?php
  $dstatus_list = unserialize(getenv('APPNAME_DSTATUS_LIST'));
  foreach($dstatus_list as $module => $cmd) {
?>
		# Status de <?php echo $module; ?> 
                <?php if (!is_array($cmd)) $cmd = array($cmd); ?>
                <?php foreach( $cmd as $c ) { ?>
                <?php echo getenv('APPNAME_HOME'); ?>/<?php echo $c; ?> 
                RCODE=${?}
		if [[ ${RCODE} -ne ${RC_OK_TERMINE} ]]
		then
			exit ${RCODE}
		fi
                <?php } ?>

<?php } ?>
	  ;;

	*) 
		# parametre invalide
		
		echo "usage: $0 ( -r | -s | -u | -h )"
		cat <<EOF

   -r | start   - demarrage de <?php echo implode(', ',array_keys($dstart_list)); ?> 
   -s | stop    - arret de <?php echo implode(', ',array_keys($dstop_list)); ?> 
   -u | restart - redemarrage de  <?php echo implode(', ',array_keys($drestart_list)); ?> 
   -h | help    - cette page

EOF
		exit ${RC_ERR_PARAM}
		;;
esac

exit ${RC_OK_TERMINE}
