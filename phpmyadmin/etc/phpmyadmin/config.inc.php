<?php echo '<?php'; ?>

// réglages pour empêcher de loguer les requêtes mysql dans un fichier
// étrangement, si les log sont activées cela perturbe l'exécution de phpmyadmin
// on désactive également l'affichage dans le navigateur des logs pour éviter
// les warnings non souhaités et surtout non corrigeable
ini_set('mysql.trace_mode', 'Off');
ini_set('display_errors', 'Off');
ini_set('display_startup_errors', 'Off');

$i = 0;

// chargement automatique des fichiers de conf modularisés
foreach(glob('<?php echo getenv('APPNAME_HOME') ?>/etc/phpmyadmin/conf.d/*') as $f) {
        include($f);
}
    
/*
 * Directories for saving/loading files from server
 */
$cfg['UploadDir'] = '<?php echo getenv('APPNAME_HOME') ?>/tmp';
$cfg['SaveDir'] = '<?php echo getenv('APPNAME_HOME') ?>/tmp';
