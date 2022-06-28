#!/bin/sh -f

### Setup and run an ELM OLMT simulation for the Kougarok Mile 64 Site
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
sleep 2

#### Postprocess
### Collapse transient simulation output into a single netCDF file
echo " "
echo " "
echo " "
cd /output/cime_run_dirs/OLMT_AK-K64G_ICB20TRCNPRDCTCBC/run
echo "**** Concatenating netCDF output - Hang tight this can take awhile ****"
ncrcat *.h0.*.nc ELM_output.nc
chmod 777 ELM_output.nc
echo "**** Concatenating netCDF output: DONE ****"
sleep 1

#echo "**** Create quicklook plots of ELM output ****"
#cd /output
#python3 /scripts/plot_ELM_output.py