#!/bin/bash

printLog () {
	echo "($(date +"%Y-%m-%d %T %Z"))" | tee -a .updb.conf.log
	printf "\t$1\n" | tee -a .updb.conf.log
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
    if [ -f ".updb.conf" ] && [ -s ".updb.conf" ]; then
        echo "This directory has been previously initialized. Run \"upd list\" to"\
            "see remote backups in use" 
    else
        echo "origin -> $PWD" > .updb.conf
		cp .updb.conf .updb.conf.prev
		echo "$lic" > .updb.conf.log
		printf "\no--------------------------- LOG ---------------------------o\n" >> .updb.conf.log
		printLog "UPD INIT -> current directory $PWD has been labeled as origin"
    fi
elif [ "$1" == "list" ]; then
	if ! [ -f .updb.conf ]; then
		printLog "Warning :: UPD config file not found !!"
		echo "You have two options either exit and run \"upd init\" and redefine your repositories or restore previous configuration if available running \"upd restore\"."
	else
		cat .updb.conf | sed 's/->/is/g'
	fi
elif [ "$1" == "restore" ]; then
	if [ -f .updb.conf.prev ]; then
		if [ -z "$(diff .updb.conf .updb.conf.prev)" ]; then
			echo "Configuration has not changed from previous state"
		else
			cp .updb.conf.prev .updb.conf
			printLog "UPD configuration has been restored to previous state."
		fi
	else
		printLog "Warning :: Config backup file seems to have been deleted by user. It's not possible to restore to the previous state."
		if [ -f .updb.conf ]; then
			cp .updb.conf .updb.conf.prev
		fi
	fi
elif [ "$1" == "log" ]; then
	if ! [ -f .updb.conf.log ]; then
		echo "$lic" > .updb.conf.log
		printf "\no--------------------------- LOG ---------------------------o\n" >> .updb.conf.log
		printLog "Warning :: Log file did'nt exist, user $USER possibly deleted it. A new one has been created. Previous actions were lost."
	else
		cat .updb.conf.log
	fi
elif [ ! -f ".updb.conf" ]; then
    echo "This directory has not been initialized."
elif [ "$1" == "add" ]; then
    if [ "${#@}" -lt 3 ]; then
        echo "Insufficient arguments for this command. See \"upd help add\"."
    else
        address=$3
        name=$2
		query=$(grep -w $name .updb.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		query2=$(grep $address .updb.conf | awk -F '->' '{ gsub(/ /,"", $2); print $2 }')
        if [ "$query" != "$name" ] && [ "$query2" != "$address" ]; then
            echo "$name -> $address" >> .updb.conf
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
			cp .updb.conf .updb.conf.prev
            echo "origin -> $PWD" > .updb.conf
            printLog "All repos has been unlinked."
        else
            shift 1
            for name in "$@"; 
            do
                query=$(grep -w $name .updb.conf)
                if [ -z "$query" ]; then
                    echo "$name is not defined. See \"upd list\"."
                else
                    cp .updb.conf .updb.conf.prev
                    grep -w -v $name .updb.conf.prev > .updb.conf
					printLog "$(echo $query | sed 's/->/unlinked from/g')"
                fi
            done
        fi
    fi
elif [ "$1" == "push" ]; then
    repos=( $(grep -w -v "origin" .updb.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
	names=( $(grep -w -v "origin" .updb.conf | awk -F '->' '{ gsub(/ /, "", $1); print $1 }') )
    for i in ${!repos[@]};
    do
		res=$(rsync -azhP --delete "$PWD/" "${repos[$i]}" | wc -l)
		if [ "$res" -gt 1 ]; then
			printLog "origin was mirrored to ${names[$i]}." 
		else
			echo "Mirror ${names[$i]} (${repos[$i]}) is up to date. No sync needed."
		fi
    done
elif [ "$1" == "pull" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help pull\"."
    else
        name=$2
        repo=$(grep -w $name .updb.conf | awk -F '->' '{ print $2 }')
        if [ -z "$repo" ]; then
            echo "$name is not registered as a backup destination. Skipping ..."
        else
			res=$(rsync -azhP --exclude '.updb.conf*' $repo "$PWD" | wc -l)
			if [ "$res" -gt 1 ]; then
				printLog "origin has been updated from $name repository." 
			else
				echo "origin is up to date. Nothing to pull."
			fi
        fi
    fi
elif [ "$1" == "edit" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help edit\"."
	else
		name=$(grep -w $2 .updb.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not recognized as a repository"
		elif [ "$name" == "origin" ]; then
			echo "UPD needs origin aliased to the address of current directory. This alias is inmutable"
		else
			cp .updb.conf .updb.conf.prev
			grep -w -v $name .updb.conf.prev > .updb.conf
			printf "Enter new address for $name destination: "
			read address
            echo "$name -> $address" >> .updb.conf
			printLog "$name address changed to $address"
		fi
	fi
elif [ "$1" == "rename" ]; then
    if [ ${#@} -lt 3 ]; then
        echo "Insufficient arguments for this command. See \"upd help rename\"."
	else
		name=$(grep -w $2 .updb.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not recognized as a repository"
		else
            address=$(grep -w $name .updb.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }')
			new_name="$3"
			cp .updb.conf .updb.conf.prev
			grep -w -v $name .updb.conf.prev > .updb.conf
            echo "$new_name -> $address" >> .updb.conf
			printLog "$address is linked now to $new_name"
		fi
	fi
elif [ "$1" == "clean" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help clean\"."
    else
        mkdir .empty
        if [ "$2" == "all" ]; then
            repos=( $(grep -w -v "origin" .updb.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
            names=( $(grep -w -v "origin" .updb.conf | awk -F '->' '{ print $1 }') )
        else
            shift 1
            names=()
            repos=()
            for name in $@; 
            do 
				repo=$(grep -w $name .updb.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }')
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
        echo "Insufficient arguments for this command. See \"upd help diff\"."
    else
		name=$(grep -w $2 .updb.conf | awk -F '->' '{ gsub(/ /,"", $1); print $1 }')
		repo=$(grep -w $2 .updb.conf | awk -F '->' '{ gsub(/ /,"", $2); print $2 }')
		if [ "$name" != "$2" ]; then
			echo "$2 is not linked to any repository"
		else
			echo "------> DIFF origin TO $name <------"
			rsync -n -rlin "$PWD/" $repo | grep -v ".updb.conf*"
			echo "------> DIFF $name TO origin <------"
			rsync -n -rlin $repo "$PWD" | grep -v ".updb.conf*"
		fi
	fi
else
    echo "Unrecognized command $1."
fi
