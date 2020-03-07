#!/usr/bin/env bash
# The Readdle Scanner Pro app (https://readdle.com/scannerpro) exports "scans"
# from my phone with filenames of the form 20200304-8.33.55 AM.jpg and
# 20200228-1.25.51 PM page 1.jpg
# I prefer 20200304-083355.jpg and 20200228-132551-001.jpg

main() {
    while getopts "h?s:" opt; do
        case "$opt" in
        h|\?)
            echo "Usage: $0 -s /path/to/dir/with/fit/files"
            exit 0
            ;;
        s)  SRCDIR=$OPTARG
            ;;
        esac
    done

    shift $((OPTIND-1))

    if [[ -z $SRCDIR || ! -d $SRCDIR ]]; then
        echo "Specify a directory with scans."
        exit 1
    fi

    case $OSTYPE in
        darwin*)
            DESTDIR="/Users/$USER"
        ;;
        linux*)
            DESTDIR="/home/$USER"
        ;;
        *)
            echo "Unknown OSTYPE: $OSTYPE"
            exit 1
        ;;
    esac

    TSTAMP=$(date +%Y%m%d-%H%M%S)
    DESTDIR="$DESTDIR/$TSTAMP-Scans"

    for f in $SRCDIR/*
    do
        basename=${f##*/}

        # Example: 20200215-12.59.27 PM.jpg
        OnePageScan="([0-9]{8})\-([0-9]{,2})\.([0-9]{2})\.([0-9]{2})\ ([APM]{2})\.([a-zA-Z]*)"
        # Example: 20200228-1.25.51 PM page 1.jpg
        MultiPageScan="([0-9]{8})\-([0-9]{,2})\.([0-9]{2})\.([0-9]{2})\ ([APM]{2})\ page\ ([0-9]?)\.([a-zA-Z]*)"

        if [[ $basename =~ $OnePageScan ]]; then
            Ymd=${BASH_REMATCH[1]}
            H=${BASH_REMATCH[2]}
            M=${BASH_REMATCH[3]}
            S=${BASH_REMATCH[4]}
            T="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[5]}")"
            E="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[6]}")"
            # TODO: Does `date` on macOS support this kind of formatting?
            # Use `date` to handle AM/PM conversion to 24 hour time
            newName="$(date -d "$Ymd $H:$M:$S $T" +"%Y%m%d-%H%M%S").$E"
        elif [[ $basename =~ $MultiPageScan ]]; then
            Ymd=${BASH_REMATCH[1]}
            H=${BASH_REMATCH[2]}
            M=${BASH_REMATCH[3]}
            S=${BASH_REMATCH[4]}
            T="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[5]}")"
            N=${BASH_REMATCH[6]}
            N=$(printf '%03d' $N)
            E="$(tr [A-Z] [a-z] <<< "${BASH_REMATCH[7]}")"
            # TODO: Does `date` on macOS support this kind of formatting?
            # Use `date` to handle AM/PM conversion to 24 hour time
            newName="$(date -d "$Ymd $H:$M:$S $T" +"%Y%m%d-%H%M%S")-$N.$E"

        else
            echo "Don't know how to process $basename"
            continue
        fi
        mkdir -p $DESTDIR
        echo "'$f' -> $DESTDIR/$newName"
        cp -af "$f" $DESTDIR/$newName
    done
}

main "$@"

