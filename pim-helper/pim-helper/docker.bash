#!/bin/bash

if [ ! -f $(dirname $0)/Docker.conf ]; then
    echoError "You should create a Docker.conf configuration file for your local environment"
else
    . $(dirname $0)/Docker.conf
fi

. $(dirname $0)/fnshs/bootstrap.fnsh

f_help ()
{
    echo ""
    echoTitle "Usage: ./dk [arg]"
    echoHelp "Boot"                    "Boot your cluster"
    echoHelp "Stop"                    "Shut down your cluster by removing containers and volumes (without database)"
    echoHelp "create"                  "Create the services and install the project from DUMP."
    echoHelp "start"                   "Start the existing services."
    echoHelp "up"                      "Create, start the services."
    echoHelp "upi"                     "Create, start the services (Interactive Mode)."
    echoHelp "ps"                      "List the containers."
    echoHelp "logs"                    "Displays log output from services."
    echoHelp "stop"                    "Stop the services."
    echoHelp "enter"                   "Enter as www-data into a container (default:${YELLOW}$ENGINE_CONTAINER${RESTORE})."
    echoHelp "root"                    "Enter as root into a container (default:${YELLOW}$ENGINE_CONTAINER${RESTORE})."
    echoHelp "sfrun"                   "Run a Symfony Command as www-data in a container (default:${YELLOW}$ENGINE_CONTAINER${RESTORE})."
    echoHelp "scrun"                   "Run a Script Command as www-data in a container (default:${YELLOW}$ENGINE_CONTAINER${RESTORE})."
    echoHelp "install"                 "Re-Run the whole project install into ${YELLOW}$ENGINE_CONTAINER${RESTORE}."
    echoHelp "install-dump"            "Re-Run the whole project install into ${YELLOW}$ENGINE_CONTAINER${RESTORE} from SQL Dump."
    echoHelp "codechecker"             "Run the codechecker script in ${YELLOW}$ENGINE_CONTAINER${RESTORE}."
    echoHelp "runtests"                "Run the runtests script in ${YELLOW}$ENGINE_CONTAINER${RESTORE}."
    echoHelp "create-dump"             "Dump the database & storage to push a new database model in ${YELLOW}$ENGINE_CONTAINER${RESTORE}."
}

case "$1" in
    'boot')
      echoTitle "Wake up your PIM."
      docker_compose ${DOCKER_COMPOSE_FILE_NAME} up -d
    ;;
    'init')
    ;;
    'a-init')
    ;;
    'b-init')
    ;;
    'clean')
        echoTitle "Remove stopped service containers."
        docker_compose $DOCKER_COMPOSE_ARGS stop
        docker_compose $DOCKER_COMPOSE_ARGS rm
    ;;
    'cleanvone')
        echoTitle "Remove stopped container $2."
        docker_compose $DOCKER_COMPOSE_ARGS stop $2
        docker_compose $DOCKER_COMPOSE_ARGS rm -v $2
    ;;

    'cleanv')
        echoTitle "Remove stopped service containers and the Voumes."
        docker_compose $DOCKER_COMPOSE_ARGS stop
        docker_compose $DOCKER_COMPOSE_ARGS rm -v
    ;;
    'create')
        echoTitle "Create and run the services"
        docker_compose $DOCKER_COMPOSE_ARGS up --build -d
        project_install_from_dump $ENGINE_CONTAINER
        project_run_queue $ENGINE_CONTAINER
    ;;
    'start')
        echoTitle "Start the existing containers"
        docker_compose $DOCKER_COMPOSE_ARGS start
        project_run_queue $ENGINE_CONTAINER
    ;;
    'buildup')
        echoTitle "Create and run the services (detached)"
        docker_compose $DOCKER_COMPOSE_ARGS up --build -d
        project_run_queue $ENGINE_CONTAINER
    ;;
    'up')
        echoTitle "Create and run the services (detached)"
        docker_compose $DOCKER_COMPOSE_ARGS up -d --build
        project_run_queue $ENGINE_CONTAINER
    ;;
    'upi')
        echoTitle "Create and run the services (attached)"
        docker_compose $DOCKER_COMPOSE_ARGS up
    ;;
    'ps')
        echoTitle "List the containers of the project"
        docker_compose $DOCKER_COMPOSE_ARGS ps
    ;;
    'logs')
        echoTitle "Displays the logs of all the services"
        docker_compose $DOCKER_COMPOSE_ARGS logs -f
    ;;
    'stop')
        echoTitle "Stop the services"
        docker_compose $DOCKER_COMPOSE_ARGS stop
    ;;
    'enter')
        CONTAINER_DEST=$ENGINE_CONTAINER
        if [ "$2" != '' ]; then
            CONTAINER_DEST="$2"
        fi
        echoTitle "Entering into ${WHITE}$CONTAINER_DEST${RESTORE} as ${LBLUE}www-data${RESTORE}"
        docker_exec $CONTAINER_DEST /bin/bash
    ;;
    'root')
        CONTAINER_DEST=$ENGINE_CONTAINER
        if [ "$2" != '' ]; then
            CONTAINER_DEST="$2"
        fi
        echoTitle "Entering into ${WHITE}$CONTAINER_DEST${RESTORE} as ${BOLD}${RED}root${RESTORE}"
        docker_exec_root $CONTAINER_DEST /bin/bash
    ;;
    'install')
        echoTitle "Install the project"
        project_install $ENGINE_CONTAINER
    ;;
    'install-dump')
        echoTitle "Install the project from SQL Dump and archived storage"
        project_install_from_dump $ENGINE_CONTAINER
    ;;
    'release-dev')
        echoTitle "Run release.bash in the project env=DEV"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/release.bash dev
    ;;
    'release-prod')
        echoTitle "Run release.bash in the project env=PROD"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/release.bash prod
    ;;
    'update')
        echoTitle "Run update.bash in the project"
        project_nppm $ENGINE_CONTAINER
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/update.bash
    ;;
    'nppm')
        echoInfo "Run NPPM"
        project_nppm $ENGINE_CONTAINER
    ;;
    'resetdb')
        echoTitle "Run resetdb.bash in the project"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/resetdb.bash
    ;;
    'resetdb-dump')
        echoTitle "Run resetdbfromdump.bash in the project"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/resetdbfromdump.bash
    ;;
    'resetdb-remote-dump')
        echoTitle "Run resetdbfromremotedump.bash in the project"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/resetdbfromremotedump.bash $2
    ;;
    'codechecker')
        echoTitle "Run codechecker.bash in the project"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/codechecker.bash
    ;;
    'runtests')
        echoTitle "Run runtests.bash in the project"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/runtests.bash
    ;;
    'sfrun')
        echoTitle "Run Symfony command in ${WHITE}$ENGINE_CONTAINER${RESTORE}"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/sfrun.bash $2 $3 $4 $5 $6 $7 $8 $9
    ;;
    'scrun')
        echoTitle "Run Script in ${WHITE}$ENGINE_CONTAINER${RESTORE}"
        docker_exec $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/scrun.bash $2 $3 $4 $5 $6 $7 $8 $9
    ;;
    'create-dump')
         echoInfo "Dumping the database & storage of ${WHITE}$ENGINE_CONTAINER${RESTORE}"
         docker_exec_root $ENGINE_CONTAINER bash $CONTAINER_PROJECT_MOUNT_DEST/scripts/createdump.bash
    ;;
    'infos')
         echoTitle "Obtaining the project informations"
         docker_compose $DOCKER_COMPOSE_ARGS ps
    ;;
    'help')
        f_help
    ;;
    *)
        echoError "${LRED}Argument ${WHITE}$1${RESTORE}${LRED} not found.${RESTORE}"
        f_help
    ;;
esac
