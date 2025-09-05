#!/bin/bash
set -euo pipefail

for YEAR in {2014..2023}; do
  for WRFCONF in {h..h}; do
    # Replace the following echo command with your actual command
    bash run.sh $YEAR $WRFCONF >"logs/${YEAR}_${WRFCONF}.out" 2>&1 &
    sleep 1800
  done
done

