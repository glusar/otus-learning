<?php
// Passwords stay out of the OS command line and are supplied by Ansible.
[$script, $root, $data, $host, $database, $user, $admin] = $argv;
$argv = [
    "$root/occ", 'maintenance:install', '--no-interaction', '--database=mysql',
    "--database-host=$host", "--database-name=$database", "--database-user=$user",
    '--database-pass=' . getenv('OTUS_DATABASE_PASSWORD'),
    "--admin-user=$admin", '--admin-pass=' . getenv('OTUS_ADMIN_PASSWORD'),
    "--data-dir=$data",
];
$_SERVER['argv'] = $argv;
$_SERVER['argc'] = count($argv);
$argc = count($argv);
require "$root/occ";
