#!/bin/sh
# =======================================================================================
# Setup and run an ELM OLMT simulation for an NGEE Arctic site
#
#
# availible site names: kougarok, teller, council, beo
# =======================================================================================

cwd=$(pwd)
cd /tools/OLMT

# =======================================================================================
# Get the input options from the command line
for i in "$@"
do
case $i in
    -sn=*|--site_name=*)
    site_name="${i#*=}"
    shift # past argument=value
    ;;
    -sg=*|--site_group=*)
    site_group="${i#*=}"
    shift # past argument=value
    ;;
    -cp=*|--case_prefix=*)
    case_prefix="${i#*=}"
    shift # past argument=value
    ;;
    -adsy=*|--ad_spinup_years=*)
    ad_spinup_years="${i#*=}"
    shift # past argument=value
    ;;
    -fsy=*|--final_spinup_years=*)
    final_spinup_years="${i#*=}"
    shift # past argument=value
    ;;
    -trsy=*|--transient_years=*)
    transient_years="${i#*=}"
    shift # past argument=value
    ;;
    -tsp=*|--timestep=*)
    timestep="${i#*=}"
    shift # past argument=value
    ;;
    -sclr=*|--scale_rain=*)
    scale_rain="${i#*=}"
    shift # past argument=value
    ;;
    -sdsclr=*|--startdate_scale_rain=*)
    startdate_scale_rain="${i#*=}"
    shift # past argument=value
    ;;    
    -scls=*|--scale_snow=*)
    scale_snow="${i#*=}"
    shift # past argument=value
    ;;
    -sdscls=*|--startdate_scale_snow=*)
    startdate_scale_snow="${i#*=}"
    shift # past argument=value
    ;;
    -scln=*|--scale_ndep=*)
    scale_ndep="${i#*=}"
    shift # past argument=value
    ;;
    -sdscln=*|--startdate_scale_ndep=*)
    startdate_scale_ndep="${i#*=}"
    shift # past argument=value
    ;;
    -sclp=*|--scale_pdep=*)
    scale_pdep="${i#*=}"
    shift # past argument=value
    ;;
    -sdsclp=*|--startdate_scale_pdep=*)
    startdate_scale_pdep="${i#*=}"
    shift # past argument=value
    ;;
    *)
        # unknown option
    ;;
esac
done
# =======================================================================================

# =======================================================================================
# Set defaults and print the selected options back to the screen before running
site_name="${site_name:-kougarok}"
site_group="${site_group:-NGEEArctic}"
case_prefix="${case_prefix:-OLMT}"
ad_spinup_years="${ad_spinup_years:-200}"
final_spinup_years="${final_spinup_years:-600}"
transient_years="${transient_years:--1}"
# -1 is the default to run all years from 1850
timestep="${timestep:-1}"
# precipitation scaling defaults
scale_rain="${scale_rain:-1.0}"
scale_snow="${scale_snow:-1.0}"
startdate_scale_rain="${startdate_scale_rain:-99991231}"
startdate_scale_snow="${startdate_scale_snow:-99991231}"
# N/P dep scaling
scale_ndep="${scale_ndep:-1.0}"
startdate_scale_ndep="${startdate_scale_ndep:-99991231}"
scale_pdep="${scale_pdep:-1.0}"
startdate_scale_pdep="${startdate_scale_pdep:-99991231}"

# print back selected or set options to the user
echo " "
echo " "
echo "*************************** OLMT run options ***************************"
echo "Site Name = ${site_name}"
echo "Site Group = ${site_group}"
echo "Case Prefix = ${case_prefix}"
echo "Number of AD Spinup Simulation Years = ${ad_spinup_years}"
echo "Number of Final Spinup Simulation Years = ${final_spinup_years}"
echo "Number of Transient Simulation Years = ${transient_years}"
echo "Model Timestep = ${timestep}"
echo " "
if [ ${scale_rain} != 1.0 ]; then
  echo "Forcing rainfall scaled by factor of ${scale_rain} starting on ${startdate_scale_rain}"
  scaling_args="--scale_rain ${scale_rain} --startdate_scale_rain ${startdate_scale_rain}"
fi
if [ ${scale_snow} != 1.0 ]; then
  echo "Forcing snowfall scaled by factor of ${scale_snow} starting on ${startdate_scale_snow}"
  scaling_args="$scaling_args  --scale_snow ${scale_snow} --startdate_scale_snow ${startdate_scale_snow}"
fi
if [ ${scale_ndep} != 1.0 ]; then
  echo "N deposition scaled by factor of ${scale_ndep} starting on ${startdate_scale_ndep}"
  scaling_args="$scaling_args --scale_ndep ${scale_ndep} --startdate_scale_ndep ${startdate_scale_ndep}"
fi 
if [ ${scale_pdep} != 1.0 ]; then
  echo "P deposition scaled by factor of ${scale_pdep} starting on ${startdate_scale_pdep}"
  scaling_args="$scaling_args --scale_pdep ${scale_pdep} --startdate_scale_pdep ${startdate_scale_pdep}"
fi
if [ ${transient_years} != -1 ]; then
  sim_years="--nyears_ad_spinup ${ad_spinup_years} --nyears_final_spinup ${final_spinup_years} \
  --nyears_transient ${transient_years}"
else
  sim_years="--nyears_ad_spinup ${ad_spinup_years} --nyears_final_spinup ${final_spinup_years}"
fi
# =======================================================================================

# =======================================================================================
# Set site codes for OLMT
if [ ${site_name} = beo ]; then
  site_code="AK-BEOG"
elif [ ${site_name} = council ]; then
  site_code="AK-CLG"
elif [ ${site_name} = kougarok ]; then
  site_code="AK-K64G"
elif [ ${site_name} = teller ]; then
  site_code="AK-TLG"
else 
  echo " "
  echo "**** EXECUTION HALTED ****"
  echo "Please select a Site Name from beo, council, kougarok, teller"
  exit 0
  echo " "
fi
echo "OLMT Site Code: ${site_code}"
# =======================================================================================

# =======================================================================================
# pause to show options before continuing
sleep 3
echo " "
echo " "
# =======================================================================================

# =======================================================================================
# create the OLMT run command
echo " "
echo "**** User OLMT run command: "
runcmd="python3 ./site_fullrun.py \
      --site ${site_code} --sitegroup ${site_group} --caseidprefix ${case_prefix} \
      ${sim_years} --tstep ${timestep} --machine docker \
      --compiler gnu --mpilib openmpi \
      --cpl_bypass --gswp3 \
      --model_root /E3SM \
      --caseroot /output \
      --ccsm_input /inputdata \
      --runroot /output \
      --spinup_vars \
      --nopointdata \
      --metdir /inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v2.c180716_NGEE-Grid/cpl_bypass_${site_name}-Grid \
      --domainfile /inputdata/share/domains/domain.clm/domain.lnd.1x1pt_${site_name}-GRID_navy.nc \
      --surffile /inputdata/lnd/clm2/surfdata_map/surfdata_1x1pt_${site_name}-GRID_simyr1850_c360x720_c171002.nc \
      --landusefile /inputdata/lnd/clm2/surfdata_map/landuse.timeseries_1x1pt_${site_name}-GRID_simyr1850-2015_c180423.nc \
      ${scaling_args} \
      & sleep 10"
echo ${runcmd}
echo " "
echo " "

echo "**** Running OLMT: "
if python3 ./site_fullrun.py \
      --site ${site_code} --sitegroup ${site_group} --caseidprefix ${case_prefix} \
      ${sim_years} --tstep ${timestep} --machine docker \
      --compiler gnu --mpilib openmpi \
      --cpl_bypass --gswp3 \
      --model_root /E3SM \
      --caseroot /output \
      --ccsm_input /inputdata \
      --runroot /output \
      --spinup_vars \
      --nopointdata \
      --metdir /inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v2.c180716_NGEE-Grid/cpl_bypass_${site_name}-Grid \
      --domainfile /inputdata/share/domains/domain.clm/domain.lnd.1x1pt_${site_name}-GRID_navy.nc \
      --surffile /inputdata/lnd/clm2/surfdata_map/surfdata_1x1pt_${site_name}-GRID_simyr1850_c360x720_c171002.nc \
      --landusefile /inputdata/lnd/clm2/surfdata_map/landuse.timeseries_1x1pt_${site_name}-GRID_simyr1850-2015_c180423.nc \
      ${scaling_args} \
      & sleep 10

then
  wait

  echo "DONE docker ELM runs !"

else
  exit &?
fi
# =======================================================================================

# =======================================================================================
#### Postprocess
### Collapse transient simulation output into a single netCDF file
echo " "
echo " "
echo " "
echo "**** Postprocessing ELM output in:"
echo "/output/cime_run_dirs/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/run"
echo " "
echo " "
cd /output/cime_run_dirs/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/run
echo "**** Concatenating netCDF output - Hang tight this can take awhile ****"
ncrcat --ovr *.h0.*.nc ELM_output.nc
chmod 777 ELM_output.nc
echo "**** Concatenating netCDF output: DONE ****"
sleep 2
# =======================================================================================
