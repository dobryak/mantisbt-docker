# MantisBT Docker toolchain

The toolchain that simplifies the configuration and deployment of
[MantisBT](https://github.com/mantisbt/mantisbt) using
[Docker](https://www.docker.com/).  

It supports both MantisBT major versions 1.x.x and 2.x.x.  

## Prerequisites

- linux  
- GNU make  
- envsubst  
- docker >= 20.10.11  
- docker-compose >= 2.2.2  

## Configuration

The toolchain contains several config files:  
`config.mk` - the main configuration file  
`.env.tmpl` - the docker-compose configuration file  
`.mt_config.env.tmpl` - MantisBT configuration file  

Files with `.tmpl` extension may contain evnironment variables in bash style
(see `man envsubst`).  
All such variables will be subsituted using the `envsubst` utility during
`make` execution. As the result the files `.env.tmpl` and `.mt_config.env.tmpl`
will be used as templates to create `.env` and `.mt_config.env` ones.  

### Choose MantisBT source for installation

You are able too choose what repository and branch to use for installation. It
is done through the `config.mk` file:  

`MANTIS_GIT_URL` - path to the MantisBT git repository  
`MANTIS_BRANCH` - branch name  

### Set up domain name

The `config.mk` file also contains configuration variable `NGINX_SERVER_NAME`
that is used to specify a domain name that one would like to use for Mantisbt.  

### MySQL configuration

This toolchain uses MySQL for MantisBT.  

To configure database credentials the `config.mk` file contains the following
variables:  

`MYSQL_DATABASE` - database name to be used for MantisBT  
`MYSQL_USER` - database user name  
`MYSQL_PASSWORD` - database user password  
`MYSQL_ROOT_PASSWORD` - database root password  

### MantisBT configuration

All the configuration variables available in MantisBT can be set using the
`.mt_config.env.tmpl` file. The configuration vairiable must follow the
following format:  
`MT_G_` + `variable_name`  
Thus, the `allow_signup` option (`$g_allow_signup` PHP variable) should be set
as `MT_G_allow_singup` in the `.mt_config.env.tmpl` file.  

After installation the whole source code of MantisBT will be available on the
host through the directory named `mantisbt_src`.  

> Note! Use the `.mt_config.env.tmpl` file only for the intial configuration.
> All further configurations must be done throught the
> `mantisbt_src/config/config_inc.php` file.

## Starting

MantisBT can be started using the `make start` command. This command will
build/rebuild everyting if needed and start/recreate containers.  

> After installation the default user is:  
> **login**: administrator  
> **password**: root  

## Stopping

Use `make stop` to stop MantisBT.  

> This command just stops containers and does not delete anything.  

## Removing/Cleaning

To remove the current installation one can use the `make remove` command.  This
command will remove all the existing containers, but leave all generated config
files, built images and created docker volumes. To remove everything and clean
up the environment use the `make clear` command. This command will remove
everything that was created during installation.  

## Backuping/Restoring

To backup the current MantisBT state one can use the `make backup` command.
This command will create backup in the `BACKUP_DIR` directory configured in the
`config.mk` file.  

To restore the state from a backup use the `make restore` command should be
used.  
