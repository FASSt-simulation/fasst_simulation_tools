#!/bin/sh -f

# First download met fording data. should add a user selectable flag here to skip
echo "***** Starting download of met forcing data *****"
sleep 1
cd /scripts/
sh download_elm_singlesite_forcing_data.sh
sleep 5

cd /
cwd=$(pwd)

cd /tools/OLMT

if python3 ./site_fullrun.py \
      --site AK-K64G --sitegroup NGEEArctic --caseidprefix OLMT \
      --nyears_ad_spinup 200 --nyears_final_spinup 600 --tstep 1 \
      --machine docker --compiler gnu --mpilib openmpi \
      --cpl_bypass --gswp3 \
      --model_root /E3SM \
      --caseroot /output \
      --ccsm_input /inputdata \
      --runroot /output \
      --spinup_vars \
      --nopointdata \
      --metdir /inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v2.c180716_kougarok-Grid/cpl_bypass_full \
      --domainfile /inputdata/share/domains/domain.clm/domain.lnd.1x1pt_kougarok-GRID_navy.nc \
      --surffile /inputdata/lnd/clm2/surfdata_map/surfdata_1x1pt_kougarok-GRID_simyr1850_c360x720_171002.nc \
      --landusefile /inputdata/lnd/clm2/surfdata_map/landuse.timeseries_1x1pt_kougarok-GRID_simyr1850-2015_c180423.nc \
      & sleep 10

then
  wait

  echo "DONE docker ELM runs !"

else
  exit &?
fi

cd ${cwd}




# for grid-cell gswp3 v2 (1901-2014)
#      --cpl_bypass --gswp3 \

# for daymet corrected gswp3 v1 ( 1980 - 2010, CONUS only)
#      --cpl_bypass --gswp3 --daymet \

# for daymet4 corrected gswp3 v2 ( 1980 - 2014, Northern America only, 1km resolution, unstructured-grid)
#      --cpl_bypass --gswp3 --daymet4 \

# user-provided cpl_bypass data
#      --metdir /Users/f9y/mygithub/pt-e3sm-inputdata/atm/datm7/atm_forcing.datm7.GSWP3_daymet.1x1pt_kougarok-NGEE/cpl_bypass_full \

# If for ELM after June-2021, turning off 'do_budgets'
#     --no_dobudgets \