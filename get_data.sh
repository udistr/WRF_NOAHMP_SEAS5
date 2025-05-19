#!/bin/bash -l

#echo $SHELL
#conda init bash
conda activate xmitgcm
#python --version
#conda info --envs
#conda init bash
#pip install attrs
cd $WRFDATA
# create folder for boundary and initial conditions

DATE=$1

ICBC=${WRFDATA}/${DATE}00

mkdir -p ${ICBC}

echo $DATE

YY1=`echo $DATE | cut -c1-4`
MM1=`echo $DATE | cut -c5-6`
DD1=`echo $DATE | cut -c7-8`

FILE="${ICBC}/ERA5-${DATE}00-sl.grib"
FILE_ARCH="${ARCH}/${DATE}00/ERA5-${DATE}00-sl.grib"

if [ ! -e "$FILE" ]; then
  if [ ! -e "$FILE_ARCH" ]; then
    echo "File $FILE does not exist, downloading"
    sed -e "s/DATE/${DATE}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" ${HOMEDIR}/get_ERA5-sl.py > get_ERA5-${DATE}-sl.py
    python get_ERA5-${DATE}-sl.py
    RC=$?
    if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
    mv ERA5-${DATE}00-sl.grib ${ICBC}/
  else
    cp ${FILE_ARCH} ${ICBC}/
  fi
else
  echo "File $FILE exist"
fi

FILE="${ICBC}/ERA5-${DATE}00-pl-int.grib"
FILE_ARCH="${ARCH}/${DATE}00/ERA5-${DATE}00-pl-int.grib"

if [ ! -e "$FILE" ]; then
  if [ ! -e "$FILE_ARCH" ]; then
    echo "File $FILE does not exist, downloading"
    sed -e "s/DATE/${DATE}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" ${HOMEDIR}/get_ERA5-pl.py > get_ERA5-${DATE}-pl.py
    python get_ERA5-${DATE}-pl.py
    RC=$?
    if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
    . /data/bin/miniconda2/envs/cdo-v1.9.9/env_cdo.sh
    cdo intlevel,1000,3000,5000,10000,20000,30000,40000,50000,70000,85000,92500,100000 ERA5-${DATE}00-pl.grib ERA5-${DATE}00-pl-int.grib
    mv ERA5-${DATE}00-pl.grib ${ICBC}/DEF_ERA5-${DATE}00-pl.grib
    mv ERA5-${DATE}00-pl-int.grib ${ICBC}/
  else
    cp ${FILE_ARCH} ${ICBC}/
  fi
else
  echo "File $FILE exist"  
fi

FILE="${ICBC}/SEAS5-${DATE}00-sl.grib"
FILE_ARCH="${ARCH}/${DATE}00/SEAS5-${DATE}00-sl.grib"

if [ ! -e "$FILE" ]; then
  if [ ! -e "$FILE_ARCH" ]; then
    echo "File $FILE does not exist, downloading"
    sed -e "s/YY1/${YY1}/g;s/MM1/${MM1}/g;s/DD1/${DD1}/g;s/Nort/${Nort}/g;s/West/${West}/g;s/Sout/${Sout}/g;s/East/${East}/g;" ${HOMEDIR}/get_SEAS5-sl.py > get_SEAS5-${DATE}-sl.py
    python get_SEAS5-${DATE}-sl.py
    RC=$?
    if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
    mv SEAS5-${DATE}00-sl.grib ${ICBC}/
  else
    cp ${FILE_ARCH} ${ICBC}/
  fi
else
  echo "File $FILE exist"
fi

variables=("geopotential" "specific_humidity" "temperature" "u_component_of_wind" "v_component_of_wind")
vstrings=("H" "Q" "T" "U" "V")

for i in "${!variables[@]}"; do
  var="${variables[$i]}"
  vstr="${vstrings[$i]}"
  FILE="${ICBC}/SEAS5_${vstr}-${DATE}00-pl.grib"
  FILE_ARCH="${ARCH}/${DATE}00/SEAS5_${vstr}-${DATE}00-pl.grib"

  if [ ! -e "$FILE" ]; then
    if [ ! -e "$FILE_ARCH" ]; then
      echo "File $FILE does not exist, downloading"
      sed -e "s/YY1/${YY1}/g; s/MM1/${MM1}/g; s/DD1/${DD1}/g; \
              s/Nort/${Nort}/g; s/West/${West}/g; s/Sout/${Sout}/g; s/East/${East}/g; \
              s/VAR/${var}/g; s/VN/${vstr}/g;" \
          ${HOMEDIR}/get_SEAS5-pl.py > get_SEAS5_${vstr}-${DATE}00-pl.py

      python get_SEAS5_${vstr}-${DATE}00-pl.py
      RC=$?
      if [ ${RC} -ne 0 ]; then
        echo "Command failed with exit code ${RC}. Exiting."
        exit 1
      fi

      mv SEAS5_${vstr}-${DATE}00-pl.grib ${ICBC}/
    else     
      cp ${FILE_ARCH} ${ICBC}/
    fi
  else
    echo "File $FILE exists"
  fi
done


exit 0
