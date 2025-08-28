#!/bin/bash
set -euo pipefail

for YEAR in {2014..2014}; do
  for WRFCONF in {d..d}; do
    # Replace the following echo command with your actual command
    bash run.sh $YEAR $WRFCONF >"logs/${YEAR}_${WRFCONF}.out" 2>&1 &
    sleep 1800
  done
done

