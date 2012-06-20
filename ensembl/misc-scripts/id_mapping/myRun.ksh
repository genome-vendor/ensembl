#!/bin/ksh

scriptname=$0

# THIS IS WHERE PERL WILL BE PICKED UP FROM:
export PATH=/software/perl-5.8.8/bin:${PATH}

function usage {
  cat >&2 <<EOT

Usage:

  ${scriptname} -c conf_file [ -m mode ]

  ... where 'conf_file' is the absolute path to the configuration file
  to use for this stable ID mapping run, and 'mode' is either left out
  (which is normally the case), or one of

    - check_only
    - normal (default)
    - mapping
    - upload

EOT
}

if [[ ! -e ./run.pl ]]; then
  print -u2 "Expected to find the following executable file here:"
  print -u2 "\trun.pl"
  exit
fi

mode="normal"

while getopts 'c:m:' opt; do
  case ${opt} in
    c)  conf=${OPTARG}  ;;
    m)  mode=${OPTARG}  ;;
    *)  usage; exit     ;;
  esac
done

if [[ -z ${conf} || -z ${mode} ]]; then
  usage
  exit
fi

if [[ ! -f ${conf} ]]; then
  print -u2 "The file '${conf}' does not exist."
  exit
fi

if [[ ${conf#/} == ${conf} ]]; then
  print -u2 "The path '${conf}' is not absolute."
  exit
fi

./run.pl --lsf --conf=${conf} --logauto --mode=${mode}

# $Id: myRun.ksh,v 1.6 2011/11/30 11:42:01 ak4 Exp $
