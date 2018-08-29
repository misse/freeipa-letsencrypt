#!/usr/bin/env bash
EMAIL="martin@devsed.se"
set -o nounset -o errexit
FIRSTTIME=false
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
    -f|--first-time)
    FIRSTTIME=true
    shift # past argument
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
  APACHEDIR="/etc/apache2/nssdb"
  APACHESVC="apache2"
elif [ $DISTRIB == 'centos'] || [ $DISTRIB = 'rhel' ]; then
  APACHEDIR="/etc/httpd/alias"
  APACHESVC="httpd"
else
  echo "-d|--distro must be set to one of the following: Ubuntu Debian Centos Rhel"
  exit 1
fi

### cron
# check that the cert will last at least 2 days from now to prevent too frequent renewal
# comment out this line for the first run
if  [[ $FIRSTTIME = false ]]
then
	certutil -d $APACHEDIR/ -V -u V -n Server-Cert -b "$(date '+%y%m%d%H%M%S%z' --date='2 days')" && exit 0
fi

# cert renewal is needed if we reached this line

# cleanup
rm -f "$WORKDIR"/*.pem
rm -f "$WORKDIR"/httpd-csr.*

# generate CSR
certutil -R -d $APACHEDIR/ -k Server-Cert -f $APACHEDIR/pwdfile.txt -s "CN=$(hostname -f)" --extSAN "dns:$(hostname -f)" -o "$WORKDIR/httpd-csr.der"

# $APACHESVC process prevents letsencrypt from working, stop it
service $APACHESVC stop

# get a new cert
letsencrypt certonly --standalone --csr "$WORKDIR/httpd-csr.der" --email "$EMAIL" --agree-tos

# remove old cert
certutil -D -d $APACHEDIR/ -n Server-Cert
# add the new cert
certutil -A -d $APACHEDIR/ -n Server-Cert -t u,u,u -a -i "$WORKDIR/0000_cert.pem"

# start $APACHESVC with the new cert
service $APACHESVC start
