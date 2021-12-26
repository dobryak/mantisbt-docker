<?php
$user = "www-data";
$userGroup = "www-data";
$adminDir = './admin';
$adminInstallPHPFile = $adminDir . '/install.php';
$configDir = './config';
$configSample = $configDir . '/config_inc.php.sample';
$configFile = $configDir . '/config_inc.php';

 $config = ['<?php'];
 $configVars = [];
 $configVarPrefix = 'MT_G_';
 $configVarPrefixLen = \strlen($configVarPrefix);
 foreach ($_ENV as $var => $val) {
     if (\strpos($var, 'MT_G_') === 0) {
         $configVar = \substr($var, $configVarPrefixLen);
         $config[] = \sprintf('$g_%s = %s;', $configVar, $val);
     }
 }

if (\file_put_contents($configFile, \implode(\PHP_EOL, $config) . \PHP_EOL) === false) {
    echo 'Failed to create a config file: ' . $configFile . \PHP_EOL;
    exit(1);
}

\chown($configFile, $user);
\chgrp($configFile, $userGroup);

if (\file_exists($adminInstallPHPFile)) {
    # install_state
    #   0 = no checks done
    #   1 = server ok, get database information
    #   2 = check the database information
    #   3 = install the database
    #   4 = get additional config file information
    #   5 = write the config file
    #   6 = post install checks
    #   7 = done, link to login or db updater
    $_POST['install'] = 2;
    $_POST['go'] = 'Install/Upgrade Database';

    require_once($adminInstallPHPFile);
    // \exec('rm -rf ' . $adminDir);
}
