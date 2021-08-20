#!/bin/bash

if [ "${#@}" -lt 1 ]; then
    echo "o-----------------------------------------------------------o"
    echo "| upd-1.0 (github.com/macardosa/upd.git)                    |"
    echo "| MIT License Copyright (c) 2021 Manuel Alejandro Cardosa   |"
    echo "*-----------------------------------------------------------*"
    echo
    echo "USAGE"
    echo "      $ upd init"
    echo "      $ upd add user@address:/path/to/dir as remote1"
    echo "      $ upd list"
    echo "      $ upd sync"
    echo "      $ upd forget remote1"
    echo "      $ upd diff"
    echo $@

elif [ "$1" == "init" ]; then
    if [ -f ".upd.conf" ] && [ -s ".upd.conf" ]; then
        echo "This directory has been previously initialized. Run \"upd list\" to"\
            "see remote backups in use" 
    else
        echo "origin -> \"$PWD\"" > .upd.conf
    fi
elif [ ! -f ".upd.conf" ]; then
    echo "This directory has not been initialized."
elif [ "$1" == "list" ]; then
    cat .upd.conf | sed 's/->/is/g'
elif [ "$1" == "add" ]; then
    if [ "${#@}" -lt 4 ]; then
        echo "Insufficient arguments for this command. See \"upd help add\"."
    elif [ "$3" != "as" ]; then
        echo "Unexpected argument \"$3\". Keyword \"as\" missing at 3rd argument."\
            "See \"upd help add\"."
    else
        address=$2
        name=$4
        query=$(grep $name .upd.conf | awk '{print $1}')
        query2=$(grep $address .upd.conf | awk '{print $1}')
        if [ "$query" != "$name" ] && [ "$query2" != "$address" ]; then
            echo "$name -> $address" >> .upd.conf
        else
            echo "$query" | sed 's/->/is/'
            echo "The alias or address is already in used."
        fi
    fi
elif [ "$1" == "forget" ]; then
    if [ "${#@}" -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help forget\"."
    else
        if [ "$2" == "all" ]; then
            echo "origin -> $PWD" > .upd.conf
            echo "All repos has been unlinked."
        else
            shift 1
            for name in "$@"; 
            do
                query=$(grep $name .upd.conf)
                if [ -z $query ]; then
                    echo "Alias $name is not defined. See \"upd list\"."
                else
                    cp .upd.conf .upd.conf.prev
                    grep -v $name .upd.conf.prev > .upd.conf
                    echo $query | sed 's/->/unlinked successfully from/g'
                fi
            done
        fi
    fi
elif [ "$1" == "push" ]; then
    repos=( $(grep -v "origin" .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
    names=( $(grep -v "origin" .upd.conf | awk -F '->' '{ print $1 }') )
    for i in ${!repos[@]};
    do
        rsync -azh "$PWD" "${repos[$i]}"
        echo "${names[$i]} is up to date." 
    done
elif [ "$1" == "pull" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help pull\"."
    else
        name=$2
        repo=$(grep $name .upd.conf | awk -F '->' '{ print $2 }')
        if [ -z "$repo" ]; then
            echo "$name is not registered as a backup destination. Skipping ..."
        else
            rsync -azh --exclude '.upd.conf*' "$repo"/ "$PWD"
            echo "Local directory has been update from $name repository." 
        fi
    fi
elif [ "$1" == "clean" ]; then
    if [ ${#@} -lt 2 ]; then
        echo "Insufficient arguments for this command. See \"upd help clean\"."
    else
        mkdir .empty
        if [ "$2" == "all" ]; then
            repos=( $(grep -v "origin" .upd.conf | awk -F '->' '{ gsub(/ /, "", $2); print $2 }') )
            names=( $(grep -v "origin" .upd.conf | awk -F '->' '{ print $1 }') )
        else
            shift 1
            names=()
            repos=()
            for name in $@; 
            do 
                repo=$(grep $name .upd.conf | awk -F '->' '{ print $2 }')
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
                printf "Repo ${names[$i]} has been cleaned\n"
            fi
        done
        rm -rf .empty
    fi
else
    printf "Unrecognized command $1."
fi

