<?php echo '<?php'; ?>

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
