#!/bin/bash

#ps -ef | grep bash

. params.sh

sdate=20171101
stime=00
#edate=20220530
#etime=00
loop=1

#sdate=$1
#stime=$2
#edate=$3
#etime=$4
#loop=$5


d=`date -u -d "${sdate}T${stime} +7 hour"  +'%Y%m%dT%H'`
#enddate=`date -u -d "${edate}T${etime} +7 hour"  +'%Y%m%dT%H'`
echo $d
#echo $enddate

echo "entering loop"
while [ $loop -le 1 ]; do

  start_time=$(date +%s.%N)
  d=`date -u -d "${d} +7 hour"  +'%Y%m%dT%H'`
  d1=`date -u -d "${d} +7 hour + 10 day"  +'%Y%m%dT%H'`

  echo "-------------------------------"
  echo "Prosess time step: $d"
  echo "-------------------------------"
  echo 

  DD1=${d:0:8}
  HH1=${d:9:2}

  echo ${DD1}T${HH1}
  bash get_data.sh $DD1 #> download.log 2>&1

exit

  EXCODE=$?
  if [ ${EXCODE} -eq 0 ]; then
    start_time_wrf=$(date +%s.%N)
    bash run_wrf.sh $DD1 $HH1 $loop
    EXCODE=$?
    end_time_wrf=$(date +%s.%N)
    execution_time_wrf=$(echo "$end_time_wrf - $start_time_wrf" | bc)
    printf "Execution time for wrf: %.6f seconds\n" $execution_time_wrf
    if [ ${EXCODE} -eq 0 ]; then
      echo "Success run_wrf.sh"
    else
      echo "Failed run_wrf.sh"
    fi
  else
    echo "Failed get_data.sh"
  fi  
  end_time=$(date +%s.%N)
  # Calculate and print the execution time
  execution_time=$(echo "$end_time - $start_time" | bc)
  printf "Execution time for iteration $i: %.6f seconds\n" $execution_time
  echo

done

