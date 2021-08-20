#!/bin/bash

printLog () {
	echo "($(date +"%Y-%m-%d %T %Z"))" | tee -a .upd.conf.log
	printf "\t$1\n" | tee -a .upd.conf.log
}

lic=$'
o-----------------------------------------------------------o
| upd-1.0 (github.com/macardosa/upd.git)                    |
| MIT License Copyright (c) 2021 Manuel Alejandro Cardosa   |
*-----------------------------------------------------------*'

help () {
    echo "$lic"
	echo
    echo "USAGE"
    echo "      $ upd init"
    echo "      $ upd add user@address:/path/to/dir as remote1"
    echo "      $ upd list"
    echo "      $ upd push"
    echo "      $ upd pull remote_alias"
    echo "      $ upd forget remote1_alias"
    echo "      $ upd rename alias new_alias"
    echo "      $ upd restore"
    echo "      $ upd diff"
    echo "      $ upd clean alias"
}

if [ "${#@}" -lt 1 ]; then
	help
elif [ "$1" == "init" ]; then
    if [ -f ".upd.conf" ] && [ -s ".upd.conf" ]; then
        echo "This directory has been previously initialized. Run \"upd list\" to"\
            "see remote backups in use" 
    else
        echo "origin -> $PWD" > .upd.conf
		cp .upd.conf .upd.conf.prev
		echo "$lic" > .upd.conf.log
		printf "\no--------------------------- LOG ---------------------------o\n" >> .upd.conf.log
		printLog "UPD INIT -> current directory $PWD has been labeled as origin"
    fi
elif [ "$1" == "list" ]; then
	if ! [ -f .upd.conf ]; then
		printLog "Warning :: UPD config file not found !!"
		echo "You have two options either exit and run \"upd init\" and redefine your repositories or restore previous configuration if available running \"upd restore\"."
	else
		cat .upd.conf | sed 's/->/is/g'
	fi
elif [ "$1" == "restore" ]; then
	if [ -f .upd.conf.prev ]; then
		if [ -z "$(diff .upd.conf .upd.conf.prev)" ]; then
			echo "Configuration has not changed from previous state"
		else
			cp .upd.conf.prev .upd.conf
			printLog "UPD configuration has been restored to previous state."
		fi
	else
		printLog "Warning :: Config backup file seems to have been deleted by user. It's not possible to restore to the previous state."
		if [ -f .upd.conf ]; then
			cp .upd.conf .upd.conf.prev
		fi
	fi
elif [ "$1" == "log" ]; then
	if ! [ -f .upd.conf.log ]; then
		echo "$lic" > .upd.conf.log
		printf "\no--------------------------- LOG ---------------------------o\n" >> .upd.conf.log
		printLog "Warning :: Log file did'nt exist, user $USER possibly deleted it. A new one has been created. Previous actions were lost."
	else
		cat .upd.conf.log
	fi
elif [ ! -f ".upd.conf" ]; then
    echo "This directory has not been initialized."
elif [ "$1" == "add" ]; then
    if [ "${#@}" -lt 3 ]; then
        echo "Insufficient arguments for this command. See \"upd help add\"."
    else
        address=$3
        name=$2
		query=$(grep -w $name .upd.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		query2=$(grep $address .upd.conf | awk -F '->' '{ gsub(/ /,"", $2); print $2 }')
        if [ "$query" != "$name" ] && [ "$query2" != "$address" ]; then
            echo "$name -> $address" >> .upd.conf
			printLog "Repo $address added as $name"
        else
            echo "The alias or address is already in used."
        fi
    fi
elif [ "$1" == "forget" ]; then
    if [ "${#@}" -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help forget\"."
    else
        if [ "$2" == "all" ]; then
			cp .upd.conf .upd.conf.prev
            echo "origin -> $PWD" > .upd.conf
            printLog "All repos has been unlinked."
        else
            shift 1
            for name in "$@"; 
            do
                query=$(grep -w $name .upd.conf)
                if [ -z "$query" ]; then
                    echo "$name is not defined. See \"upd list\"."
                else
                    cp .upd.conf .upd.conf.prev
                    grep -w -v $name .upd.conf.prev > .upd.conf
					printLog "$(echo $query | sed 's/->/unlinked from/g')"
                fi
            done
        fi
    fi
elif [ "$1" == "push" ]; then
    repos=( $(grep -w -v "origin" .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
    names=( $(grep -w -v "origin" .upd.conf | awk -F '->' '{ print $1 }') )
    for i in ${!repos[@]};
    do
        rsync -azh --delete "$PWD/" "${repos[$i]}"
        printLog "origin was mirrored to ${names[$i]}." 
    done
elif [ "$1" == "pull" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help pull\"."
    else
        name=$2
        repo=$(grep -w $name .upd.conf | awk -F '->' '{ print $2 }')
        if [ -z "$repo" ]; then
            echo "$name is not registered as a backup destination. Skipping ..."
        else
            rsync -azh --exclude '.upd.conf*' $repo "$PWD"
            printLog "origin has been updated from $name repository." 
        fi
    fi
elif [ "$1" == "edit" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help edit\"."
	else
		name=$(grep -w $2 .upd.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not recognized as a repository"
		elif [ "$name" == "origin" ]; then
			echo "UPD needs origin aliased to the address of current directory. This alias is inmutable"
		else
			cp .upd.conf .upd.conf.prev
			grep -w -v $name .upd.conf.prev > .upd.conf
			printf "Enter new address for $name destination: "
			read address
            echo "$name -> $address" >> .upd.conf
			printLog "$name address changed to $address"
		fi
	fi
elif [ "$1" == "rename" ]; then
    if [ ${#@} -lt 3 ]; then
        echo "Insufficient arguments for this command. See \"upd help rename\"."
	else
		name=$(grep -w $2 .upd.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not recognized as a repository"
		else
            address=$(grep -w $name .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }')
			new_name="$3"
			cp .upd.conf .upd.conf.prev
			grep -w -v $name .upd.conf.prev > .upd.conf
            echo "$new_name -> $address" >> .upd.conf
			printLog "$address is linked now to $new_name"
		fi
	fi
elif [ "$1" == "clean" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help clean\"."
    else
        mkdir .empty
        if [ "$2" == "all" ]; then
            repos=( $(grep -w -v "origin" .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
            names=( $(grep -w -v "origin" .upd.conf | awk -F '->' '{ print $1 }') )
        else
            shift 1
            names=()
            repos=()
            for name in $@; 
            do 
				repo=$(grep -w $name .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }')
                if [ -z "$repo" ]; then
                    echo "Repo $name doesn't exist. Skipping ..."
                else
                    repos+=( $repo )
                    names+=( $name )
                fi
            done
        fi
        for i in ${!names[@]};
        do
            printf "Are you sure do you want to clean ${names[$i]} -> ${repos[$i]}? [Y,n] "
            read var
            if [ "$var" == "Y" ]; then
                rsync -az --delete .empty/ ${repos[$i]}
                printLog "Repo ${names[$i]} has been cleaned."
            fi
        done
        rm -rf .empty
    fi
elif [ "$1" == "diff" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help clean\"."
    else
		name=$(grep -w $2 .upd.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not linked to any repository"
		else
			rsync -az --dry-run "$PWD/" $name
		fi
	fi
else
    echo "Unrecognized command $1."
fi
