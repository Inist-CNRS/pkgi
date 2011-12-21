<?php $apache_options = explode(',',getenv('APPNAME_APACHE_OPTIONS')); ?>
<?php echo '<?php'; ?>

include '/etc/dokuwiki/dokuwiki.php';
$conf['useacl']      = 1;
$conf['superuser']   = '@admin';
$conf['savedir']     = '<?php echo getenv('APPNAME_HOME'); ?>/var/lib/dokuwiki/data';

<?php if (in_array('htaccess',$apache_options)) { ?>
$conf['userewrite']  = 1;
$conf['useslash']    = 1;
<?php } ?>
