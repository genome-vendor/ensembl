#!/bin/ksh

scriptname=$0

# THIS IS WHERE PERL WILL BE PICKED UP FROM:
export PATH=/software/perl-5.8.8/bin:${PATH}

function usage {
  cat <<EOT

Usage:

  ${scriptname} -h dbhost [-P dbport] -u dbuser -p dbpass -d dbname

EOT
}

if [[ ! -e ./manage_id_mapping_tables.pl ]]; then
  print -u2 "Expected to find the following executable file here:"
  print -u2 "\tmanage_id_mapping_tables.pl"
  exit
fi

dbport="3306"

while getopts 'h:P:u:p:d:' opt; do
  case ${opt} in
    h)  dbhost=${OPTARG}    ;;
    P)  dbport=${OPTARG}    ;;
    u)  dbuser=${OPTARG}    ;;
    p)  dbpass=${OPTARG}    ;;
    d)  dbname=${OPTARG}    ;;
    *)  usage; exit         ;;
  esac
done

if [[
  -z ${dbhost} || -z ${dbport} ||
  -z ${dbuser} || -z ${dbpass} ||
  -z ${dbname}
]]; then
  usage
  exit
fi

./manage_id_mapping_tables.pl \
  -host ${dbhost} \
  -port ${dbport} \
  -user ${dbuser} \
  -pass ${dbpass} \
  -dbname ${dbname}

# $Id: myManager.ksh,v 1.6 2011/11/30 11:42:01 ak4 Exp $
