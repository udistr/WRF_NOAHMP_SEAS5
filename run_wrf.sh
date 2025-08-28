#!/bin/bash

#-------------------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------------------

export LD_LIBRARY_PATH=/home/ARO.local/udist/Build_WRF/LIBRARIES/grib2/lib

#DATE1=20161101
#HH1=00

DATE1=$1
HH1=$2
LOOP=$3
WRFCONF=$4

HH2=00
#history interval
HI=180

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

if [ ! -f ./geo_em.d02.nc ]; then
  cp ${HOMEDIR}/run_sbatch_geogrid.sh .
  sed -i "s|WPSRUN|${WPSRUN}|g" run_sbatch_geogrid.sh
  echo "Run geogrid"
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

if [ ! -f DoneUngrib1 ]; then
  rm -f FILE_ERA5:*
  echo "Run ungrib 1"
  ./ungrib.exe > ung1.txt 2>&1
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneUngrib1
fi

if [ ! -f DoneMetgrid1 ]; then
  rm -f met_em.d0*
  echo "Run metgrid 1"
  ./metgrid.exe > met1.txt 2>&1
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneMetgrid1
fi

# generate SEAS5 boundary conditions

sed -i "s/start_date =.*/start_date = '${D1b}:00:00','${D1b}:00:00','${D1b}:00:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D2}:00:00','${D2}:00:00','${D2}:00:00'/g" namelist.wps
sed -i "s/prefix.*/prefix = 'FILE_SEAS5'/g" namelist.wps
sed -i "s/fg_name.*/fg_name = 'FILE_SEAS5'/g" namelist.wps
./link_grib.csh ${ICBC}/SEAS5*
#ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable

if [ ! -f DoneUngrib2 ]; then
  rm -f FILE_SEAS5:*
  echo "Run ungrib 2"
  ./ungrib.exe > ung2.txt 2>&1
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneUngrib2
fi

if [ ! -f DoneMetgrid2 ]; then
  echo "Run metgrid 2"
  ./metgrid.exe > met2.txt 2>&1
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneMetgrid2
fi

#-------------------------------------------------------------------------------------
# WRF
#-------------------------------------------------------------------------------------

echo "WRF"

# create WRF folder
WRFRUN=${WRFDIR}/run_${DATE1}_${WRFCONF}
cp -r ${WRFDIR}/RUN_SEAS5_TEMPLATE ${WRFRUN}

echo "entering WRFDIR: ${WRFRUN}"
cd ${WRFRUN}
cp "${HOMEDIR}/namelist.input_${WRFCONF}" ./namelist.input
cp ${HOMEDIR}/mk_crop.py .

rm -f met_em.d0*
echo "linlking from ${WPSRUN}/met_em.d0"

if [ -d ${ARCH}/${WPSRUN} ]; then
  ln -sf ${ARCH}/${WPSRUN}/met_em.d0* ./
else
  ln -sf ${WPSRUN}/met_em.d0* ./
fi 

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
if [ ! -f DoneReal1 ]; then
  cp "${HOMEDIR}/run_sbatch_real.sh" .
  sed -i "s|WRFRUN|${WRFRUN}|g;" run_sbatch_real.sh
  sed -i "s|WRF_SEAS5|SEAS5_${DATE1}_${WRFCONF}|g;" run_sbatch_real.sh
  sbatch --wait run_sbatch_real.sh
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneReal1
fi

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
if [ ! -f DoneReal2 ]; then
  cp "${HOMEDIR}/run_sbatch_real.sh" .
  sed -i "s|WRFRUN|${WRFRUN}|g;" run_sbatch_real.sh
  sed -i "s|WRF_SEAS5|SEAS5_${DATE1}_${WRFCONF}|g;" run_sbatch_real.sh
  sbatch --wait run_sbatch_real.sh
  RC=$?
  if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
  touch DoneReal2
fi

/arch/Users/udist/miniconda/envs/nco/bin/ncks -O -x -v VEGFRA wrflowinp_d01 wrflowinp_d01
/arch/Users/udist/miniconda/envs/nco/bin/ncks -O -x -v VEGFRA wrflowinp_d02 wrflowinp_d02

echo "Update crop fields in wrfinput"
. /data/bin/miniconda2/envs/pythonUdi-v1.0/env_pythonUdi.sh

if [ ! -f ${ARCH}/FR.nc ]; then
  cp -r ${WRFDATA}/agri .
  cp -r ${WRFDATA}/border .
  cp -r ${HOMEDIR}/plot_wheat.py .
  cp -r ${WPSRUN}/geo_em.d02.nc .
  ipython ./plot_wheat.py
  rm -r agri plot_wheat.py geo_em.d02.nc border
  cp FR.nc ${ARCH}/
else
  cp ${ARCH}/FR.nc .
fi

ipython ./mk_crop.py

sed -i "s/end_year.*/end_year = ${YY2}, ${YY2}, ${YY2},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM2},   ${MM2},   ${MM1},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD2},   ${DD2},   ${DD2},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH2},   ${HH2},   ${HH2},/g" namelist.input

sed -i "s/history_interval.*/history_interval = ${HI},   ${HI},   ${HI},/g" namelist.input

# update initial conditions of the inner domain

echo "Submiting job to queue: wrf"
cp "${HOMEDIR}/run_sbatch.sh" .
sed -i "s|WRFRUN|${WRFRUN}|g;" run_sbatch.sh
sed -i "s|WRF_SEAS5|SEAS5_${DATE1}_${WRFCONF}|g;" run_sbatch.sh
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

#-------------------------------------------------------------------------------------
# ARCHIVE
#-------------------------------------------------------------------------------------

echo "Moving files to archive: ${ARCH}"
#echo "Moving icbc folder: ${ICBC}"
#rm -r ${ARCH}/${DATE1}00
#mv ${ICBC} ${ARCH}/
#echo "Moving wps folder: ${WPSRUN}"
#rm -r ${ARCH}/WPS_SEAS5_${DATE1}
#mv ${WPSRUN} ${ARCH}/
echo "Moving wrf folder: ${WRFRUN}"
rm -r ${ARCH}/run_${DATE1}_${WRFCONF}
mv ${WRFRUN} ${ARCH}/




