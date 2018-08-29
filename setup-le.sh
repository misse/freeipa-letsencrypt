#!/usr/bin/bash
set -o nounset -o errexit
HELP=false
while [[ $# -gt 0 ]]
do
  key="$1"
  
  case $key in
    -d|--distro)
    DISTRIB="${2,,}"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    HELP=true
    shift # past argument
    ;;
  esac
done

if [[ $HELP == true ]]
then
  echo "Usage: $0 -d|--distro (Ubuntu|Debian|Centos|Rhel) [-f|--firsttime] [-h|--help]"
  exit 1
fi


WORKDIR=$(pwd)

if [ $DISTRIB == 'ubuntu' ] || [ $DISTRIB = 'debian' ]; then
  PM="apt-get"
elif [ $DISTRIB == 'centos'] || [ $DISTRIB = 'rhel' ]; then
  PM="dnf"
else
  echo "-d|--distro must be set to one of the following: Ubuntu Debian Centos Rhel"
  exit 1
fi
$PM install letsencrypt -y

ipa-cacert-manage install "$WORKDIR/ca/DSTRootCAX3.pem" -n DSTRootCAX3 -t C,,
ipa-certupdate -v

ipa-cacert-manage install "$WORKDIR/ca/LetsEncryptAuthorityX3.pem" -n letsencryptx3 -t C,,
ipa-certupdate -v

"$(dirname "$0")/renew-le.sh" -d $DISTRIB --first-time
