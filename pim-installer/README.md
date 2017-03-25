# Akeneo PIM Docker Automated Installer

## Usage

This repository allows you to install easily 32 differents setup of the [Akeneo PIM](https://www.akeneo.com/) using docker with the [@damien-carcel](https://github.com/damien-carcel/Dockerfiles) work

Available installations :
- CE / EE editions (to make the EE working you should have the rights access)
- 1.4 | 1.5 | 1.6 | 1.7 | master versions
- orm | odm storage
- php-5.6 | php-7.0 engine

To make it works: (must be enhanced)

```bash
    mkdir -p Akeneo/PIM_Automated
    cd Akeneo
    git clone https://github.com/anaelChardan/AkeneoTools.git
    cd PIM_Automated
    ln -s ./../AkeneoTools/pim-installer/install_pim.bash ./
    ln -s ./../AkeneoTools/pim-installer/files ./
    cp ./../AkeneoTools/pim-installer/files/config/installer/parameters.bash.dist ./files/etc/parameters.bash
    vim ./files/etc/parameters.bash
    ./install_pim.bash (1.4|1.5|1.6|master) (ce|ee) (orm|odm) (php-5.6|php-7.0)
```

The script will create two folder next to your script : backup and installed_pims

This has been tested on MacOS Sierra only

## Performance needed, you should use [docker-sync](https://github.com/EugenMayer/docker-sync) or [docker-NFS](https://github.com/IFSight/d4m-nfs) at least

For docker-sync, you can use this [branch](https://github.com/anaelChardan/AkeneoTools/tree/akeneo-tools-docker-sync) 

## Bonus

It also setup XDebug to work with Docker Native for Mac and PHPStorm

You must set an alias for the IP of the MobyVM using 

```bash
    sudo ifconfig en0 alias 10.254.254.254 255.255.255.0
    sudo ifconfig lo0 alias 10.254.254.254 255.255.255.0
```

Then to link docker to phpStorm :

You have to install socat (brew install socat)

```bash
    socat TCP-LISTEN:2375,reuseaddr,fork,bind=localhost UNIX-CONNECT:/var/run/docker.sock
```

Then you can add docker (only the path is different)

![PHPStorm Docker](/assets/docker_phpstorm.png)

Next, you should add your xdebug config (which is already configured in containers)

![PHPStorm XDebug](/assets/xdebug_phpstorm.png)

Finally, you have to configure a server:

This example is for my computer and a PIM 1.5 CE ORM PHP-5.6 so adapt to your needs

![PHPStorm LOCALHOST](/assets/server_localhost.png)

And for behat

![PHPStorm LOCALHOST_BEHAT](/assets/server_localhost_behat.png)

## Bored about use a port into your browser ?

In your mac you have an apache by default, so you can use vhost to redirect all your pims

You can use this [tutorial](https://jason.pureconcepts.net/2014/11/configure-apache-virtualhost-mac-os-x/) and use a 
the pim-conf available in the etc folder which give you all vhosts available by this tool if you use the same config as the dist.

==============================================================

Now you can develop as you want and debug as you want, enjoy :smirk_cat:


