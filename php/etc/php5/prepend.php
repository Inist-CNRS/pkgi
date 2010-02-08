<?php echo '<?php'; ?>

foreach( glob('<?php echo getenv('APPNAME_HOME'); ?>/etc/php5/prepend.d/*.php') as $f) {
    include $f;
}
