#!/bin/bash

#-------------------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------------------

export LD_LIBRARY_PATH=/home/ARO.local/udist/Build_WRF/LIBRARIES/grib2/lib

DATE1=20220520
HH1=00
HH2=00

DATE1=$1
HH1=$2
LOOP=$3

ICBC=${WRFDATA}/${DATE1}00

DATE2=$(date -d "${DATE1} +7 months" +%Y%m%d)

YY1=`echo $DATE1 | cut -c1-4`
MM1=`echo $DATE1 | cut -c5-6`
DD1=`echo $DATE1 | cut -c7-8`
YY2=`echo $DATE2 | cut -c1-4`
MM2=`echo $DATE2 | cut -c5-6`
DD2=`echo $DATE2 | cut -c7-8`

D1=${YY1}-${MM1}-${DD1}_${HH1}
D1b=${YY1}-${MM1}-${DD1}_12
D2=${YY2}-${MM2}-${DD2}_${HH2}

STR=${YY1}${MM1}${DD1}-${YY2}${MM2}${DD2}

#-------------------------------------------------------------------------------------
# WPS
#-------------------------------------------------------------------------------------

echo "WPS"

# create WPS folder
WPSRUN=${WPSDIR}/WPS_SEAS5_${DATE1}
cp -r ${WPSDIR}/WPS_SEAS5_TEMPLATE/ ${WPSRUN}/

echo "entering WPSRUN dir: ${WPSRUN}"
cd ${WPSRUN}
if [ ! -f ./namelist.wps ]; then
    cp "${HOMEDIR}/namelist.wps" .
fi

echo "Run geogrid"
if [ ! -f ./geo_em.d02.nc ]; then
  cp ${HOMEDIR}/run_sbatch_geogrid.sh .
  sed -i "s/WPSRUN/${WPSRUN}/g" run_sbatch_geogrid.sh
  sbatch --wait run_sbatch_geogrid.sh
  #./geogrid.exe > geog.txt 2>&1
fi

# generate ERA5 initial conditions

sed -i "s/start_date =.*/start_date = '${D1}:00:00','${D1}:00:00','${D1}:00:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D1}:00:00','${D1}:00:00','${D1}:00:00'/g" namelist.wps
sed -i "s/prefix.*/prefix = 'FILE_ERA5'/g" namelist.wps
sed -i "s/fg_name.*/fg_name = 'FILE_ERA5'/g" namelist.wps
./link_grib.csh ${ICBC}/ERA5-*
#ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable

echo "Run ungrib 1"
rm -f FILE_ERA5:*
./ungrib.exe > ung1.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Run metgrid 1"
rm -f met_em.d0*
./metgrid.exe > met1.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

# generate SEAS5 boundary conditions

sed -i "s/start_date =.*/start_date = '${D1b}:00:00','${D1b}:00:00','${D1b}:00:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D2}:00:00','${D2}:00:00','${D2}:00:00'/g" namelist.wps
sed -i "s/prefix.*/prefix = 'FILE_SEAS5'/g" namelist.wps
sed -i "s/fg_name.*/fg_name = 'FILE_SEAS5'/g" namelist.wps
./link_grib.csh ${ICBC}/SEAS5*
#ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable

echo "Run ungrib 2"
rm -f FILE_SEAS5:*
./ungrib.exe > ung2.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Run metgrid 2"
./metgrid.exe > met2.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

#-------------------------------------------------------------------------------------
# WRF
#-------------------------------------------------------------------------------------

echo "WRF"

# create WRF folder
WRFRUN=${WRFDIR}/run_${DATE1}
cp -r ${WRFDIR}/RUN_SEAS5_TEMPLATE ${WRFRUN}
cp ${HOMEDIR}/mk_crop.py ${WRFRUN}

echo "entering WRFDIR: ${WRFRUN}"
cd ${WRFRUN}
if [ ! -f ./namelist.input ]; then
    cp "${HOMEDIR}/namelist.input" .
fi
rm -f met_em.d0*
echo "linlking from ${WPSRUN}/met_em.d0"
ln -sf ${WPSRUN}/met_em.d0* ./

if [ $LOOP -eq 0 ];
then
  sed -i "s/ restart .*/ restart = .false.,/g" namelist.input
else
  sed -i "s/ restart .*/ restart = .true.,/g" namelist.input
fi

# first time real (simple LSM)

sed -i "s/ sf_surface_physics.*/ sf_surface_physics                  = 0,    0,    0,/g" namelist.input

sed -i "s/start_year.*/start_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/start_month.*/start_month = ${MM1},   ${MM1},   ${MM1},/g" namelist.input
sed -i "s/start_day.*/start_day = ${DD1},   ${DD1},   ${DD1},/g" namelist.input
sed -i "s/start_hour.*/start_hour = ${HH1},   ${HH1},   ${HH1},/g" namelist.input

sed -i "s/end_year.*/end_year = ${YY2}, ${YY2}, ${YY2},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM2},   ${MM2},   ${MM2},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD2},   ${DD2},   ${DD2},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH2},   ${HH2},   ${HH2},/g" namelist.input

echo "running real.exe for boundary conditions"
./real.exe > real1.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

# second time real (NoahMP LSM)

sed -i "s/ sf_surface_physics.*/ sf_surface_physics                  = 4,    4,    4,/g" namelist.input

sed -i "s/start_year.*/start_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/start_month.*/start_month = ${MM1},   ${MM1},   ${MM1},/g" namelist.input
sed -i "s/start_day.*/start_day = ${DD1},   ${DD1},   ${DD1},/g" namelist.input
sed -i "s/start_hour.*/start_hour = ${HH1},   ${HH1},   ${HH1},/g" namelist.input

sed -i "s/end_year.*/end_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM1},   ${MM1},   ${MM1},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD1},   ${DD1},   ${DD1},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH1},   ${HH1},   ${HH1},/g" namelist.input

echo "running real.exe for initial conditions"
./real.exe > real2.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Update crop fields in wrfinput"
. /data/bin/miniconda2/envs/pythonUdi-v1.0/env_pythonUdi.sh

if [ ! -f ${ARCH}/FR.nc ]; then
  cp -r ${HOMEDIR}/agri .
  cp -r ${HOMEDIR}/plot_wheat.py .
  cp -r ${WPSRUN}/geo_em.d02.nc .
  ipython ./plot_wheat.py
  rm -r agri plot_wheat.py geo_em.d02.nc
  cp FR.nc ${ARCH}/
else
  cp ${ARCH}/FR.nc
fi

ipython ./mk_crop.py

sed -i "s/end_year.*/end_year = ${YY2}, ${YY2}, ${YY2},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM2},   ${MM2},   ${MM1},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD2},   ${DD2},   ${DD2},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH2},   ${HH2},   ${HH2},/g" namelist.input

# update initial conditions of the inner domain

echo "Submiting job to queue: wrf"
if [ ! -f ./run_sbatch.sh ]; then
  cp "${HOMEDIR}/run_sbatch.sh" .
  sed -i "s/WRFRUN/${WRFRUN}/g;" run_sbatch.sh
fi
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

#-------------------------------------------------------------------------------------
# ARCHIVE
#-------------------------------------------------------------------------------------

echo "Moving files to archive: ${ARCH}"
echo "Moving icbc folder: ${WRFDATA}/${DATE1}00"
mv ${WRFDATA}/${DATE1}00 ${ARCH}/
echo "Moving wps folder: ${WRFDATA}/${DATE1}00"
mv ${WPSRUN} ${ARCH}/
echo "Moving wrf folder: ${WRFDATA}/${DATE1}00"
mv ${WRFRUN} ${ARCH}/




