<?php

class Pkgi
{
    var $APPNAME = '';
    var $MODULES = array();
    var $MODULES_LIST = array();

    var $env_path = null;
    var $tpl_path = null;
    var $dst_path = null;
    var $php_path = null;

    function Pkgi($env_path = null, $tpl_path = null, $dst_path = null)
    {
        $current_dir = substr(dirname(__FILE__), strrpos(dirname(__FILE__),'/')+1);
        if (!preg_match('/^[a-z]+$/i',$current_dir)) $current_dir = 'src';
        $this->env_path = ($env_path == null) ? dirname(__FILE__).'/../'.$current_dir.'.env' : $env_path;
        $this->tpl_path = ($tpl_path == null) ? realpath(dirname(__FILE__)) : $tpl_path;
        $this->dst_path = $dst_path;
        $this->php_path = getenv('PHP');
        if ($this->php_path === false)  $this->php_path = '/usr/bin/php'; 
    }
  
    function run()
    {
        echo "--- ETAPE 1 : Choisissez un nom d'application\n";
        $this->choose_appli_name();
        echo "Le nom d'application suivant sera utilise : ".$this->APPNAME."\n";
        echo "--- ETAPE 2 : Choisissez les modules a activer\n";
        $this->build_module_list();
        $this->choose_modules();
        if (count($this->MODULES) > 1)
            echo "Les modules suivants seront utilises : ".implode(',',$this->MODULES)."\n";
        else
            echo "Le module suivant sera utilise : ".implode(',',$this->MODULES)."\n";
    
        echo "--- ETAPE 3 : Charge les variables d'environnement\n";
        $env = array();
        $this->load_env($env);
        $this->check_env($env);
        $this->write_env($env);
        $this->load_extra_env($env); // a faire apres write_env car on veut pas les sauvegarder

        // get the APPLI_HOME from the env
        if ($this->dst_path == null)
        {
            $dst = $env[$this->APPNAME.'_HOME'];
            if (!file_exists($dst)) @mkdir($dst, 0777, true);
            if (file_exists($dst))
                $this->dst_path = $dst;
            else
                die("$dst doesn't exist");
        }
    
        echo "--- ETAPE 4 : Ecrit l'instance des templates\n";
        $this->write_tpl_instance();

        echo "* Votre application ".$this->APPNAME." est prette.\n";
        echo "* Elle dispose des modules suivants : ".implode(',',$this->MODULES)."\n";
        echo "* Les paramètres ont été sauvegardés dans : ".realpath($this->env_path)."\n";
        echo "* Vous pouvez à tout moment modifier un parametre.\n";
        echo "* Pensez alors à relancer le build pour regénérer les fichiers de conf et les lanceurs.\n";
    
    }

    function build_module_list()
    {
        $this->MODULES_LIST = array();
        $dir = dirname(__FILE__);
        $d = opendir($dir);
        while ($file = readdir($d))
        {
            if ($file == '.' || $file == '..' ||
                $file == 'CVS' || $file == '.svn' ||
                $file == 'core')
                continue;
            else if (is_dir($dir.'/'.$file))
                $this->MODULES_LIST[] = $file;
        }
        closedir($d);
    }
  
    function choose_modules()
    {
        // on recherche MODULES dans l'environement
        // si on le trouve pas alors on pose la question
        if ($s = getenv($this->APPNAME.'_MODULES'))
        {
            $this->MODULES = $this->_filter_valide_modules(explode(',',$s));
        }
        else if (file_exists($this->env_path))
        {
            $data = file_get_contents($this->env_path);
            if (preg_match('/'.$this->APPNAME.'_MODULES=(.+)/i',$data,$res))
                $this->MODULES = $this->_filter_valide_modules(explode(',',trim($res[1],'" ')));
        }
    
        // si rien n'a ete trouve alors on demande a l'utilisateur d'entrer des modules au clavier
        while (count($this->MODULES) == 0)
        {
            $prompt = "Entrez le nom des modules separes par des virgules que vous voulez activer dans votre application\nparmis les modules suivants ".implode(',',$this->MODULES_LIST)." : ";
            $this->MODULES = $this->_filter_valide_modules(explode(',',readline($prompt)));
        }
    
        // ajoute le module core dont tous les autres dependent en tout premier de la liste
        $this->MODULES = array_merge(array('core'), $this->MODULES);
    }

    function _filter_valide_modules($modules_to_check)
    {
        // filtre les modules suivant la liste des modules disponibles
        $mod_ok = array();
        foreach($modules_to_check as $m)
            if (in_array($m, $this->MODULES_LIST))
                $mod_ok[] = $m;
        return $mod_ok;
    }
  
    function choose_appli_name()
    {
        // on recherche APPNAME dans l'environement
        // si on le trouve pas alors on cherche dans le fichier XXXX.env
        if ($s = getenv('APPNAME'))
        {
            $this->APPNAME = $s;
        }
        else if (file_exists($this->env_path))
        {
            $data = file_get_contents($this->env_path);
            if (preg_match('/APPNAME=(.+)/i',$data,$res))
                $this->APPNAME = trim($res[1],'" ');
        }

        // rien n'a ete trouve alors on demande a l'utilisateur de l'entrer au clavier
        if ($this->APPNAME == '')
        {
            do {
                $prompt = "Entrez le nom de votre application (en lettres majuscules): ";
                $this->APPNAME = readline($prompt);
            } while (!preg_match('/[A-Z]+/',$this->APPNAME));
        }
    }


    /**
     * Charge dans le tableau passé en parametre toutes les variables d'env trouvées
     * soit dans l'environement courant, soit dans le fichier XXX.env
     */
    function load_env(&$env)
    {
        $env['APPNAME'] = $this->APPNAME;
        $env[$this->APPNAME.'_MODULES'] = implode(',',$this->MODULES);

        // construit une liste des variables d'env a tester
        $env_to_check = $this->_build_env_to_check();
    
        $data = file_exists($this->env_path) ? file_get_contents($this->env_path) : '';
        foreach($env_to_check as $e => $e_option)
        {
            $e = $this->APPNAME.'_'.$e;
            if (getenv($e) === FALSE)
            {
                if (preg_match('/export\s+'.$e.'=(.*)/',$data,$res))
                {
                    $env[$e] = trim($res[1],'" ');
                    putenv('$e="'.$env[$e].'"');
                }
            }
            else
                $env[$e] = getenv($e);
        }
    }

    function _build_env_to_check()
    {
        // construit une liste des variables d'env a tester
        // en fonction des modules choisis
        $env_to_check = array();
        foreach($this->MODULES as $m)
        {
            $ini_path = dirname(__FILE__).'/'.$m.'/config.ini';
            if (!file_exists($ini_path)) continue;

            // execute les balises php eventuelles contenues dans config.ini
            $output = shell_exec($this->php_path.' '.$ini_path);
            $ini_path = dirname(__FILE__).'/config.ini.tmp';
            file_put_contents($ini_path,$output);
      
            $ini_data = parse_ini_file($ini_path);
            for ($i = 0 ; $i<count($ini_data['env']) ; $i++)
            {
        
                $env_to_check[$ini_data['env'][$i]] = array();
                $env_to_check[$ini_data['env'][$i]][] = $ini_data['env-desc'][$i];
                $env_to_check[$ini_data['env'][$i]][] = $ini_data['env-choix'][$i] != '' ? explode(',',$ini_data['env-choix'][$i]) : array();
                $env_to_check[$ini_data['env'][$i]][] = isset($ini_data['env-default'][$i]) ? $ini_data['env-default'][$i] : '';
            }
            unlink($ini_path);
        }
        return $env_to_check;
    }
  
    /**
     * Verifie que les variables d'environement passées en paramètre
     * sont bien définies et qu'il n'en manque pas suivant les modules selectionnés
     */
    function &check_env(&$env)
    {
        echo "Verification de la presence des variables d'environnement ...\n";
    
        // construit une liste des variables d'env a tester
        $env_to_check = $this->_build_env_to_check();
        foreach($env_to_check as $e => $e_option)
        {
            $e = $this->APPNAME.'_'.$e;
            $v = isset($env[$e]) ? $env[$e] : NULL;
            if ($v == NULL || $v == '')
            {
                $v = getenv($e);
                if ($v === FALSE || $v == '') 
                {
                    echo "\n";
                    echo "Signification de $e : ".$e_option[0]."\n";
                    if (count($e_option[1]) > 0)
                        echo "Valeurs possibles de $e : ".implode(' ou ', $e_option[1])."\n";
                    $v_default = $e_option[2] != '' ? "[defaut=".$e_option[2]."] " : '';
                    $prompt = "La variable $e est indefinie, entrez sa valeur ".$v_default.": ";
                    $v = readline($prompt);
                    if ($v == '') $v = $e_option[2]; // si on a rien repondu, on prend la valeur par defaut
                }
                $env[$e] = $v;
                putenv("$e=$v");
            }
            echo "La variable suivante sera utilisee : $e=$v\n";
        }
        return $env;
    }


    function write_env($env)
    {
        $filename = $this->env_path;
        echo "Ecriture des variables d'environnement dans ".realpath($filename)."\n";
        $data = '# Attention : n\'éditez pas ce fichier manuellement car il sera regénéré par pkgi au prochain build'."\n";
        foreach($env as $k => $v)
        {
            // ecriture dans le fichier XXX.env
            $data .= sprintf("export %s=\"%s\"\n", $k, $v);
      
            // ecriture dans l'environnement
            // on replace tout les prefixes par APPNAME car c'est le prefix des variables d'env dans nos templates
            if (preg_match('/'.$this->APPNAME.'_(.+)/',$k,$res))
                putenv("APPNAME_".$res[1]."=$v");
        }
        $set_fmode = (!file_exists($filename));
        file_put_contents($filename,$data);
        if ($set_fmode) {
            // si le fichier d'env est ecrit pour la premiere fois on regle les droits pour une bonne sécurité
            chmod($filename, 0600);
        }
    }

    /**
     * Charge :
     * APPNAME_DSTART_LIST
     * APPNAME_DSTOP_LIST
     * APPNAME_DRESTART_LIST
     * APPNAME_DSTATUS_LIST
     * APPNAME_ENV_FILE_PATH
     */
    function load_extra_env(&$env)
    {
        // construit une liste des demons a demarrer et arreter
        // cette liste sera utilisee par appli pour lancer/arreter d'un coups tous les demons
        $dstart_list   = array();
        $dstop_list    = array();
        $drestart_list = array();
        $dstatus_list  = array();
        foreach($this->MODULES as $m)
        {
            $ini_path = dirname(__FILE__).'/'.$m.'/config.ini';
            if (!file_exists($ini_path)) continue;
            $ini_data = parse_ini_file($ini_path);
            if (isset($ini_data['start-daemon']) && $ini_data['start-daemon'] != '')
                $dstart_list[$m] = $ini_data['start-daemon'];
            if (isset($ini_data['stop-daemon']) && $ini_data['stop-daemon'] != '')
                $dstop_list[$m]  = $ini_data['stop-daemon'];
            if (isset($ini_data['restart-daemon']) && $ini_data['restart-daemon'] != '')
                $drestart_list[$m]  = $ini_data['restart-daemon'];
            if (isset($ini_data['status-daemon']) && $ini_data['status-daemon'] != '')
                $dstatus_list[$m]  = $ini_data['status-daemon'];
        }
        $dstart_list   = serialize($dstart_list);
        $dstop_list    = serialize($dstop_list);
        $drestart_list = serialize($drestart_list);
        $dstatus_list  = serialize($dstatus_list);
    
        putenv('APPNAME_DSTART_LIST='.$dstart_list);
        putenv('APPNAME_DSTOP_LIST='.$dstop_list);
        putenv('APPNAME_DRESTART_LIST='.$drestart_list);
        putenv('APPNAME_DSTATUS_LIST='.$dstatus_list);

        // ajout du chemin vers le fichier d'environement cree
        putenv('APPNAME_ENV_FILE_PATH='.realpath($this->env_path));
    }


    function build_templates_list()
    {
        $ret = array();
        foreach($this->MODULES as $m)
        {
            $list[$m] = array_values(ls($this->tpl_path.'/'.$m,"//i"));
            $n = 0;
            foreach( $list[$m] as $l)
            {
                $list[$m][$n] = str_replace($this->tpl_path.'/'.$m.'/', '', $list[$m][$n]);
                if (is_file($l))
                    if ( dirname($l) == $this->tpl_path )
                        unset($list[$m][$n]);
                if (trim($list[$m][$n]) == '' ||
                    trim($list[$m][$n]) == '/' ||
                    // ne liste pas config.ini dans les templates a instancier
                    // car c'est un simple fichier de description
                    $list[$m][$n] == 'config.ini')
                    unset($list[$m][$n]);
                $n++;
            }
            sort($list[$m]);
            $ret = array_merge($ret,$list);
        }
        return $ret;
    }

    // WRITE TPL INSTANCES
    function write_tpl_instance()
    {
        $tlist = $this->build_templates_list();
    
        // first we check that modified files will not be overwriten
        $modified_file = array();
        foreach($tlist as $m => $templates)
            foreach($templates as $t)
            {
                if ($t == 'pkgi.env') continue; // special case for this file, do not touch it ! 

                $t_dst     = $this->dst_path.'/'.$t;
                $t_dst_md5 = $this->dst_path.'/.pkgi/lastmd5/'.$t;
	        if (is_link($t_dst)) {
		  // handle symlinks
		  if (file_exists($t_dst_md5) && readlink($t_dst) != readlink($t_dst_md5)) {
                        $modified_file[] = $t_dst;
		  }
		} else if (is_dir($t_dst)) {
		} else if (is_file($t_dst)) {
  		  // handle files
                  if (file_exists($t_dst) &&
                      file_exists($t_dst_md5))
                  {
                      $md5_current   = md5(file_get_contents($t_dst));
                      $md5_lastbuild = file_get_contents($t_dst_md5);
                      if ($md5_current != $md5_lastbuild)
                          $modified_file[] = $t_dst;
	    	  }
                }
            }

        if (count($modified_file) > 0)
        {
            do {
                $prompt = "Les fichiers suivants ont été modifié manuellement depuis le dernier build :\n".
                    implode("\n",$modified_file)."\n".
                    "Voulez vous les écraser (o/n) ? :\n";
                $answer = readline($prompt);
            } while (!preg_match('/^[on]+/i',$answer));
            if (preg_match('/^n/i',$answer))
                die("Build interrompu !\n");
        }
    
        // then we instanciate the templates
        foreach($tlist as $m => $templates)
            foreach($templates as $t)
            {
                if ($t == 'pkgi.env') continue; // special case for this file, do not touch it ! 

                $t_src     = $this->tpl_path.'/'.$m.'/'.$t;
                $t_dst     = $this->dst_path.'/'.$t;
                $t_dst_md5 = $this->dst_path.'/.pkgi/lastmd5/'.$t;
                echo "Ecriture de ".$t_dst."\n";
                if (file_exists($t_src) && !is_dir($t_src) && !is_link($t_src))
                {
                    @mkdir(dirname($t_dst), 0777, true);
                    $output = shell_exec($this->php_path.' '.$t_src);
                    file_put_contents($t_dst, $output);
                    // setting the rights
                    if (is_executable($t_src) || preg_match('/^bin\//',$t))
                        chmod($t_dst,0700);
                    else
                        chmod($t_dst,0600);
                    // store the file md5
                    @mkdir(dirname($t_dst_md5), 0777, true);
                    file_put_contents($t_dst_md5, md5($output));
                }
                else if (is_link($t_src)) {
                    // manage symlinks
                    @unlink($t_dst);
                    symlink(readlink($t_src),$t_dst);
                    @unlink($t_dst_md5);
                    symlink(readlink($t_src),$t_dst_md5);
                }
                else if (substr($t_src,-1) == '/')
                    @mkdir($t_dst, 0777, true);
                else
                    trigger_error($t_src." cannot be found",E_USER_ERROR);
            }
    }

}






function ls($dir, $mask /*.php$|.txt$*/)
{
    static $i = 0;
    $files = Array();
    $d = opendir($dir);
    $empty = true;
    while ($file = readdir($d))
    {
        if ($file == '.' || $file == '..' ||
            $file == 'CVS' || $file == '.svn' || $file == '.dummy' || preg_match('/~$/',$file) ||
            !preg_match($mask, $file)) continue;
        $empty = false;
        if (is_dir($dir.'/'.$file) && !is_link($dir.'/'.$file))
        {
            $files += ls($dir.'/'.$file, $mask);
            continue;
        }
        $files[$i++] = $dir.'/'.$file;
    }
    closedir($d);
    if ($empty) $files[$i++] = $dir.'/';
    return $files;
}



if (!function_exists('readline'))
{
    function readline($prompt)
    {
        echo $prompt;
        $in = trim(fgets(STDIN)); // Maximum windows buffer size
        return $in;
    }
}


/**
 * Replace file_put_contents()
 *
 * @category    PHP
 * @package     PHP_Compat
 * @link        http://php.net/function.file_put_contents
 * @author      Aidan Lister <aidan@php.net>
 * @version     $Revision: 1.2 $
 * @internal    resource_context is not supported
 * @since       PHP 5
 * @require     PHP 4.0.0 (user_error)
 */
if (!defined('FILE_USE_INCLUDE_PATH')) { define('FILE_USE_INCLUDE_PATH', 1); }
if (!defined('LOCK_EX')) { define('LOCK_EX', 2); }
if (!defined('FILE_APPEND')) { define('FILE_APPEND', 8); }
if (!function_exists('file_put_contents')) {
    function file_put_contents($filename, $content, $flags = null, $resource_context = null)
        {
            // If $content is an array, convert it to a string
            if (is_array($content)) {
                $content = implode('', $content);
            }

            // If we don't have a string, throw an error
            if (!is_scalar($content)) {
                user_error('file_put_contents() The 2nd parameter should be either a string or an array',
                           E_USER_WARNING);
                return false;
            }

            // Get the length of data to write
            $length = strlen($content);

            // Check what mode we are using
            $mode = ($flags & FILE_APPEND) ?
                'a' :
                'wb';

            // Check if we're using the include path
            $use_inc_path = ($flags & FILE_USE_INCLUDE_PATH) ?
                true :
                false;

            // Open the file for writing
            if (($fh = @fopen($filename, $mode, $use_inc_path)) === false) {
                user_error('file_put_contents() failed to open stream: Permission denied',
                           E_USER_WARNING);
                return false;
            }

            // Attempt to get an exclusive lock
            $use_lock = ($flags & LOCK_EX) ? true : false ;
            if ($use_lock === true) {
                if (!flock($fh, LOCK_EX)) {
                    return false;
                }
            }

            // Write to the file
            $bytes = 0;
            if (($bytes = @fwrite($fh, $content)) === false) {
                $errormsg = sprintf('file_put_contents() Failed to write %d bytes to %s',
                                    $length,
                                    $filename);
                user_error($errormsg, E_USER_WARNING);
                return false;
            }

            // Close the handle
            @fclose($fh);

            // Check all the data was written
            if ($bytes != $length) {
                $errormsg = sprintf('file_put_contents() Only %d of %d bytes written, possibly out of free disk space.',
                                    $bytes,
                                    $length);
                user_error($errormsg, E_USER_WARNING);
                return false;
            }

            // Return length
            return $bytes;
        }
}


?>
