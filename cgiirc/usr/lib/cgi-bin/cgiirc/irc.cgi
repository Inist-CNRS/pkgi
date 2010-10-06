<?php

$f = '/usr/lib/cgi-bin/cgiirc/'.basename(__FILE__);
$c = file_get_contents($f);

echo str_replace('/etc/cgiirc', getenv('APPNAME_HOME').'/etc/cgiirc', $c);
