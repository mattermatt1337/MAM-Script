#!/bin/bash

MAMID=

WORKDIR=/opt/MAM  # Directory for temp files.
cd ${WORKDIR}

#################################################################################
#################################################################################
echo Checking existing cookie file.
MAMUID=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?snatch_summary | tee ${WORKDIR}/MAM.json | jq .uid 2>/dev/null`

if [ "${MAMUID}x" = "x" ]
then
  echo Session invalid.
  if [ "x$MAMID" = "x__LONGSTRING__" ]
  then
    echo Please update the MAMID in the script
    exit 1
  fi

  MAMUID=`curl -s -b "mam_id=${MAMID}" -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?snatch_summary | tee ${WORKDIR}/MAM.json | jq .uid 2>/dev/null`
  if [ "${MAMUID}x" = "x" ]
  then
    echo " => Cannot create new session!"
    exit 1
  else
    echo " => New Session created"
    exit 1
  fi
  else
  echo " => Existing session valid"
fi

UNSAT_COUNT=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?snatch_summary | jq '.unsat.count'`
UNSAT_LIMIT=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?snatch_summary | jq '.unsat.limit'`

if [ $? -ne 0 ]
then
  echo " => Failed to get unsat torrents - aborting."
  exit 1
else
  echo " => Unsat Torrents: $UNSAT_COUNT / $UNSAT_LIMIT"
fi

if [[ $UNSAT_COUNT -lt $UNSAT_LIMIT ]]
then
  echo "Looks good!"
  exit 0
else
  echo "Too much unsatisfied torrents!"
  exit 1
fi
