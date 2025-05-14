#!/bin/bash

#-------------------------------------------------------------------------------------
# Setup
#-------------------------------------------------------------------------------------

export LD_LIBRARY_PATH=/home/ARO.local/udist/Build_WRF/LIBRARIES/grib2/lib

DATE1=20220520
HH1=00

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
D2=${YY2}-${MM2}-${DD2}_${HH2}

STR=${YY1}${MM1}${DD1}-${YY2}${MM2}${DD2}

#-------------------------------------------------------------------------------------
# WPS
#-------------------------------------------------------------------------------------

echo "WPS"

# create WPS folder
WPSRUN=${WPSDIR}/WPS_SEAS5_${sdate}
cp -r ${WPSDIR}/WPS_SEAS5_TEMPLATE/ ${WPSRUN}/

cd ${WPSRUN}

# generate ERA5 initial conditions

sed -i "s/start_date =.*/start_date = '${D1}:00:00','${D1}:00:00','${D1}:00:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D1}:00:00','${D1}:00:00','${D1}:00:00'/g" namelist.wps
sed -i "s/prefix.*/prefix = 'FILE_ERA5'/g" namelist.wps
sed -i "s/fg_name.*/fg_name = 'FILE_ERA5'/g" namelist.wps
./link_grib.csh ${ICBC}/ERA5-*
#ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable

echo "Run ungrib"
rm -f FILE_ERA5:*
./ungrib.exe > ung.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Run metgrid"
rm -f met_em.d0*
./metgrid.exe > met.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi


# generate SEAS5 boundary conditions

sed -i "s/start_date =.*/start_date = '${D1}:12:00','${D1}:12:00','${D1}:12:00'/g" namelist.wps
sed -i "s/end_date.*/end_date =   '${D2}:00:00','${D2}:00:00','${D2}:00:00'/g" namelist.wps
sed -i "s/prefix.*/prefix = 'FILE_SEAS5'/g" namelist.wps
sed -i "s/fg_name.*/fg_name = 'FILE_SEAS5'/g" namelist.wps
./link_grib.csh ${ICBC}/SEAS5*
#ln -sf ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable

echo "Run ungrib"
rm -f FILE_SEAS5:*
./ungrib.exe > ung.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Run metgrid"
./metgrid.exe > met.txt 2>&1
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

#-------------------------------------------------------------------------------------
# WRF
#-------------------------------------------------------------------------------------

# create WRF folder
WRFRUN=${WRFDIR}/run_${sdate}
cp -r ${WRFDIR}/RUN_SEAS5_TEMPLATE ${WRFRUN}

cd ${WRFRUN}
rm -f met_em.d0*
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
./real.exe
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
./real.exe
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

# update initial conditions of the inner domain

echo "Submiting job to queue: wrf"
sbatch --wait run_sbatch.sh
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi










echo "Running ndown"



cd ../run_10D_ndown
cp ../run_10D/wrfinput_d03 wrfndi_d02
cp ../run_10D/wrfout_d02_${YY1}-${MM1}-${DD1}_00\:00\:00 wrfout_d01_${YY1}-${MM1}-${DD1}_00\:00\:00


sed -i "s/start_year.*/start_year = ${YY1}, ${YY1}, ${YY1},/g" namelist.input
sed -i "s/start_month.*/start_month = ${MM1},   ${MM1},   ${MM1},/g" namelist.input
sed -i "s/start_day.*/start_day = ${DD1},   ${DD1},   ${DD1},/g" namelist.input
sed -i "s/start_hour.*/start_hour = ${HH1},   ${HH1},   ${HH1},/g" namelist.input

sed -i "s/end_year.*/end_year = ${YY2}, ${YY2}, ${YY2},/g" namelist.input
sed -i "s/end_month.*/end_month = ${MM2},   ${MM2},   ${MM2},/g" namelist.input
sed -i "s/end_day.*/end_day = ${DD2},   ${DD2},   ${DD2},/g" namelist.input
sed -i "s/end_hour.*/end_hour = ${HH2},   ${HH2},   ${HH2},/g" namelist.input

./ndown.exe
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi

echo "Moving wrf files to archive"

cd ${WRFDIR}

mv wrfout* ${OUTDIR}/WRF/
mv wrfrst_d0[1,2,3]_${YY2}-${MM2}-${DD2}_00:00:00 ${OUTDIR}/WRF/
RC=$?
if [ ${RC} -ne 0 ]; then echo "Command failed with exit code ${RC}. Exiting.";  exit 1; fi
rm wrfrst*
cp wrfinput_d01 ${OUTDIR}/WRF/wrfinput_d01_${YY1}-${MM1}-${DD1}
cp wrfinput_d02 ${OUTDIR}/WRF/wrfinput_d02_${YY1}-${MM1}-${DD1}
cp wrfinput_d03 ${OUTDIR}/WRF/wrfinput_d03_${YY1}-${MM1}-${DD1}
cp wrflowinp_d01 ${OUTDIR}/WRF/wrflowinp_d01_${YY1}-${MM1}-${DD1}
cp wrflowinp_d02 ${OUTDIR}/WRF/wrflowinp_d02_${YY1}-${MM1}-${DD1}
cp wrflowinp_d03 ${OUTDIR}/WRF/wrflowinp_d03_${YY1}-${MM1}-${DD1}
cp wrfbdy_d01 ${OUTDIR}/WRF/wrfbdy_d01_${YY1}-${MM1}-${DD1}




