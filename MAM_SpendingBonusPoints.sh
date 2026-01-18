#### CREDITS ####
Slightly edited by me
Metcalfe (/f/t/76212) and basqpcez (https://hub.docker.com/r/basqpcez/mam-point-spender)

Run as cronjob: 42 7,19 * * * .../MAM_SpendingBonusPoints.sh > /tmp/Spend.log 2>/tmp/Spend.err
#################

#!/bin/bash

MAMID=

BUFFER=55000      # Stay above 55000, so always have 5k available, even after buying a wedge.
VIP=              # Set this to 1 to enable buying of VIP
WEDGEHOURS=4      # Buy a wedge every 4 hours - set to 0 to not buy wedges
WORKDIR=/opt/MAM  # Directory for temp files.

POINTSURL='https://www.myanonamouse.net/json/bonusBuy.php/?spendtype=upload&amount='
VIPURL='https://www.myanonamouse.net/json/bonusBuy.php/?spendtype=VIP&duration=max&_='
WEDGEURL='https://www.myanonamouse.net/json/bonusBuy.php/?spendtype=wedges&source=points&_='$TIMESTAMP

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

POINTS=`jq .seedbonus < ${WORKDIR}/MAM.json`

TIMESTAMP=`date +%s%3N`

# First - find out how many points we have.
echo Collecing current points.
POINTS=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?id=${MAMUID} | jq '.seedbonus'`

if [ $? -ne 0 ]
then
  echo " => Failed to get number of bonus points - aborting."
  exit 1
else
  echo " => Current points: $POINTS"
fi

# Check to see if we should buy a wedge. (Hours above, less 10 minutes to cope with offsets)
if [ $WEDGEHOURS -gt 0 ]
then
  WEDGEMINS=`expr $WEDGEHOURS \* 60 - 10`
  find ${WORKDIR}/wedge.last -mmin -${WEDGEMINS} 2>/dev/null | grep -i wedge.last > /dev/null 2>/dev/null
  if [ $? -ne 0 ]
  then
    echo Need to buy a wedge!
    if [ $POINTS -lt 50000 ]
    then
      echo "Not enough points, aborting"
      #exit 1
    fi

    curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies $WEDGEURL
    touch ${WORKDIR}/wedge.last

    POINTS=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies https://www.myanonamouse.net/jsonLoad.php?id=${MAMUID} | jq '.seedbonus'`
  fi
fi

# Maximize VIP
if [ "x$VIP" != "x" ]
then
  VIPRESULT=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies ${VIPURL}${TIMESTAMP} 2>/dev/null | jq .success`
  if [ "x$VIPRESULT" != "xtrue" ]
  then
    echo VIP purchase failed!
  else
    echo VIP purchased!
  fi
fi

for i in 100 20 5 1
do
  echo Checking to spend ${i}GB
  UPLOADREQUIRED=`expr $i \* 500 + ${BUFFER}`
  while [ $POINTS -gt $UPLOADREQUIRED ]
  do
    echo $POINTS is more than $UPLOADREQUIRED - buying ${i}G of upload
    NEWPOINTS=`curl -s -b ${WORKDIR}/MAM.cookies -c ${WORKDIR}/MAM.cookies ${POINTSURL}${i}'&_='$TIMESTAMP | jq '.seedbonus' | sed -e 's/\..*$//'`
    if [ $? -ne 0 ]
    then
      echo Spend failed - cannot see new Bonus points.
      exit 1
    fi

    if [ $NEWPOINTS -lt $POINTS ]
    then
      POINTS=$NEWPOINTS
    else
      echo Points did not change - spending failed.
      exit 1
    fi
  done
done
