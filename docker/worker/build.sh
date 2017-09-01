#!/bin/sh
#=============================================================================
#
#  File    : build.sh
#  Date    : July 24th, 2017
#  Author  : Oleg Lodygensky
#
#  Change log:
#  - Jul 24th,2017 : Oleg Lodygensky; creation
#
#  OS      : Linux, mac os x
#
#  Purpose : this script creates and starts a new Docker container for the XWHEP worker
#
#=============================================================================


# Copyrights     : CNRS
# Author         : Oleg Lodygensky
# Acknowledgment : XtremWeb-HEP is based on XtremWeb 1.8.0 by inria : http://www.xtremweb.net/
# Web            : http://www.xtremweb-hep.org
#
#      This file is part of XtremWeb-HEP.
#
#    XtremWeb-HEP is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    XtremWeb-HEP is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with XtremWeb-HEP.  If not, see <http://www.gnu.org/licenses/>.
#
#


THISOS=`uname -s`

case "$THISOS" in

  Darwin )
    DATE_FORMAT='+%Y-%m-%d %H:%M:%S%z'
    ;;

  Linux )
    DATE_FORMAT='--rfc-3339=seconds'
    ;;

  * )
    fatal  "OS not supported ($THISOS)"  TRUE
    ;;

esac

#=============================================================================
#
#  Function  fatal (Message, Force)
#
#=============================================================================
fatal ()
{
  msg="$1"
  FORCE="$2"
  [ "$msg" ]  ||  msg="Ctrl+C"

  echo  "$(date "$DATE_FORMAT")  $SCRIPTNAME  FATAL : $msg"

  exit 1
}

#=============================================================================
#
#  Function  usage ()
#
#=============================================================================
usage()
{
cat << END_OF_USAGE
  This script create a new container for the XWHEP worker.
  This is all created from sources downloaded from github.
END_OF_USAGE

  exit 0
}


#=============================================================================
#
#  Main
#
#=============================================================================
trap  fatal  SIGINT  SIGTERM



ROOTDIR="$(dirname "$0")"
SCRIPTNAME="$(basename "$0")"

XWJOBUID="$(date '+%Y-%m-%d-%H-%M-%S')"


IMAGENAME_WORKER="xwworkerimg_${XWJOBUID}"
CONTAINERNAME_WORKER="xwworkercontainer_${XWJOBUID}"
DOCKERFILE="${ROOTDIR}/Dockerfile"
TMPDOCKERFILE="${ROOTDIR}/workerdockerfile_${XWJOBUID}"


while [ $# -gt 0 ]; do

  case "$1" in

    --help )
      usage
      ;;

    -v | --verbose | --debug )
      VERBOSE=1
      set -x
      ;;

  esac

  shift

done

type docker > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	fatal "docker not installed"
fi

if [ ! -f ${DOCKERFILE} ] ; then
	fatal "${DOCKERFILE} not found"
fi

ls xwhep-worker-*.deb > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	fatal "no worker Debian package found"
fi

VERSION=`ls  xwhep-worker-*.deb | cut -d ' ' -f 2 | tail -1 | sed "s/xwhep-worker-//g" | sed "s/\.deb//g"`
ls xwhep-worker-${VERSION}.deb > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	fatal "File not found : xwhep-worker-${VERSION}.deb"
fi

sed  "s/ENV XWVERSION.*/ENV XWVERSION \"${VERSION}\"/g" ${DOCKERFILE} > ${TMPDOCKERFILE}
mv ${TMPDOCKERFILE} ${DOCKERFILE}

docker build --force-rm --tag ${IMAGENAME_WORKER} .

cat << EOF_RUN
You can now start your worker running:
     docker run --name ${CONTAINERNAME_WORKER} ${IMAGENAME_WORKER}
EOF_RUN


exit 0
###########################################################
#     EOF        EOF     EOF        EOF     EOF       EOF #
###########################################################
