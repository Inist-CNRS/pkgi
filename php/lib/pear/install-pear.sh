<?php
// 
// Ce script se charge de :
// - telecharger le script go-pear sur http://pear.php.net/go-pear
// - le modifier pour regler les bon chemins en fonction des variables d'environnement de l'applicatif
// - retirer les questions inutiles
// - rajouter du code pour transformer ce script en script sh 
//   de facon a permettre le reglage du cache_dir car il semble impossible de le regler en amont
// - afficher le resultat
// Remarque : Ce script étant un tdemplate, lorsqu''il sera instancié, le code php généré sera
//            en faite un script sh executable par l'utilisateur s''il desire installer pear
//            dans son application
//

$ct_params = array();
if ( getenv('http_proxy') !== FALSE || getenv('HTTP_PROXY') !== FALSE)
{
  $http_proxy = ( getenv('http_proxy') === FALSE ? getenv('HTTP_PROXY') : getenv('http_proxy') );
	$http_proxy = str_replace('http://','',$http_proxy);
  $ct_params['http'] = array( 'proxy' => 'tcp://'.$http_proxy, 'request_fulluri' => true );
}
$ct = stream_context_create($ct_params);
$gopear = file_get_contents("http://pear.php.net/go-pear", false, $ct);

// reglages des chemins
$gopear = str_replace('detect_install_dirs();','detect_install_dirs();
$prefix    = "'.getenv('APPNAME_HOME').'/lib/pear";
$temp_dir  = "'.getenv('APPNAME_HOME').'/tmp/pear";
$php_dir   = "'.getenv('APPNAME_HOME').'/lib/pear/php";
$cache_dir = "'.getenv('APPNAME_HOME').'/tmp/pear/cache";
$test_dir  = "'.getenv('APPNAME_HOME').'/tmp/pear/tests";
$doc_dir   = "'.getenv('APPNAME_HOME').'/tmp/pear/docs";
',$gopear);
$gopear = str_replace('PEAR_Config::singleton()',
                      'PEAR_Config::singleton(\''.getenv('APPNAME_HOME').'/lib/pear/pear.conf'.'\')',
                      $gopear);

// repond automatiquement aux questions et retire les "press Enter to continue"
$gopear = str_replace('fgets($tty, 1024);','',$gopear);
$gopear = str_replace('trim(fgets($tty, 1024));','"";',$gopear);
$gopear = str_replace('$install_pfc = !stristr(fgets($tty, 1024), "n");','$install_pfc = !stristr("Y", "n");',$gopear);
$gopear = str_replace('$alter_phpini = !stristr(fgets($tty, 1024), "n");','$alter_phpini = !stristr("n", "n");',$gopear);

$gopear = '#/bin/sh
PHP=${PHP:=php}
PHP="${PHP} -d short_open_tag=0 "
export PHP
FILE=`basename "$0"`
DIR=`dirname "$0"`
cd "$DIR"
$PHP -C -q -d output_buffering=1 "$FILE" $@
mkdir -p '.getenv('APPNAME_HOME').'/tmp/pear/cache
$PHP -r \'$f="'.getenv('APPNAME_HOME').'/lib/pear/bin/pear"; file_put_contents($f,str_replace("pearcmd.php \\"$@\\"","pearcmd.php -c '.getenv('APPNAME_HOME').'/lib/pear/pear.conf \\"$@\\"",file_get_contents($f)));\'
$PHP -r \'$f="'.getenv('APPNAME_HOME').'/lib/pear/bin/peardev"; file_put_contents($f,str_replace("pearcmd.php \\"$@\\"","pearcmd.php -c '.getenv('APPNAME_HOME').'/lib/pear/pear.conf \\"$@\\"",file_get_contents($f)));\'
$PHP -r \'$f="'.getenv('APPNAME_HOME').'/lib/pear/bin/pecl"; file_put_contents($f,str_replace("pearcmd.php \\"$@\\"","peclcmd.php -c '.getenv('APPNAME_HOME').'/lib/pear/pear.conf \\"$@\\"",file_get_contents($f)));\'
'.getenv('APPNAME_HOME').'/lib/pear/bin/pear config-set cache_dir '.getenv('APPNAME_HOME').'/tmp/pear/cache
'.getenv('APPNAME_HOME').'/lib/pear/bin/pear config-set auto_discover 1
'.getenv('APPNAME_HOME').'/lib/pear/bin/pear channel-discover pear.pxxo.net
'.getenv('APPNAME_HOME').'/lib/pear/bin/pear config-show
exit
<?php
ob_end_clean();
set_time_limit(0);
ob_implicit_flush(true);
?>'.$gopear;

echo $gopear;

?>
