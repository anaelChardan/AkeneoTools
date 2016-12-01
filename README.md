# Akeneo PIM Docker Automated Installer

## Usage

This repository allows you to install easily 32 differents setup of the [Akeneo PIM](https://www.akeneo.com/) using docker with the [@damien-carcel work](https://github.com/damien-carcel/Dockerfiles)

These are the options :
- CE / EE editions (to make the EE working you should have the rights access)
- 1.4 | 1.5 | 1.6 | master versions
- orm | odm storage
- php-5.6 | php-7.0 engine

To make it works:

You must configure the script under the ###### USER CONFIGURABLE PART ########

```bash
  ./install_pim.bash (1.3|1.4|1.5|1.6|master) (ce|ee) (orm|odm) (php-5.6|php-7.0)
```

This has been tested on MacOS Sierra only