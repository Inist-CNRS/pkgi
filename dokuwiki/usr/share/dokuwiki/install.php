<?php echo "<?php"; ?>

define('DOKU_INC', '<?php echo getenv('APPNAME_HOME'); ?>/usr/share/dokuwiki/');
define('DOKU_CONF',DOKU_INC.'conf/');
define('DOKU_LOCAL',DOKU_INC.'conf/');
<?php

echo "?>";
echo file_get_contents('/usr/share/dokuwiki/install.php');
