#/bin/sh

PHP=${PHP:=php}
PHP="${PHP} -d short_open_tag=0 "
export PHP

FILE=`basename "$0"`
DIR=`dirname "$0"`

cd "$DIR"
exec $PHP -C -q -d output_buffering=1 "$FILE" $@ 
exit ${?}
<?php
ob_end_clean();
set_time_limit(0);
ob_implicit_flush(true);

require_once dirname(__FILE__).'/pkgi.inc.php';

$pkgi = new Pkgi( null, realpath(dirname(__FILE__)) );
$pkgi->run();

?>