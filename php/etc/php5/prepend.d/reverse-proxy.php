<?php echo '<?php'; ?> 

<?php if (getenv('APPNAME_APACHE_BEHIND_REVERSE_PROXY') == 'yes') { ?>

// this code make reverse proxy transparent for the hosted PHP application
if (isset($_SERVER['REMOTE_ADDR'])) {
    $_SERVER['REMOTE_ADDR'] = isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : $_SERVER['REMOTE_ADDR'];
}
if (isset($_SERVER['HTTP_HOST'])) {
    $_SERVER['HTTP_HOST'] = isset($_SERVER['HTTP_X_FORWARDED_HOST']) ? $_SERVER['HTTP_X_FORWARDED_HOST'] : $_SERVER['HTTP_HOST'];
}
if (isset($_SERVER['SERVER_ADDR'])) {
    $_SERVER['SERVER_ADDR'] = isset($_SERVER['HTTP_X_FORWARDED_SERVER']) ? $_SERVER['HTTP_X_FORWARDED_SERVER'] : $_SERVER['SERVER_ADDR'];
}
if (isset($_SERVER['SERVER_PORT'])) {
<?php if (preg_match('/^https/', getenv('APPNAME_APACHE_URL_ROOT'))) { ?>
    $_SERVER['SERVER_PORT'] = 443;
    $_SERVER['HTTPS']       = 'on';
<?php } else { ?>
    $_SERVER['SERVER_PORT'] = 80;
    unset($_SERVER['HTTPS']);
<?php } ?>
}


<?php } ?>
