<?php
$version = explode(',',getenv('APPNAME_VERSION'));
if (in_array('dev',$version)) {
  echo '<?php phpinfo(); ?>';
}
?>