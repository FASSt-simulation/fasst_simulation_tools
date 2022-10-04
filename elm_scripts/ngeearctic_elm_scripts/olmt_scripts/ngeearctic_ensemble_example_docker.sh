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
### Setup and run an example ELM OLMT ensemble simulation for a NGEE-Arctic research site
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
    -pl=*|--param_list=*)
    param_list="${i#*=}"
    shift # past argument=value
    ;;
    -ne=*|--num_ens=*)
    num_ens="${i#*=}"
    shift # past argument=value
    ;;
    -ng=*|--num_groups=*)
    num_groups="${i#*=}"
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
case_prefix="${case_prefix:-OLMT_ens}"
ad_spinup_years="${ad_spinup_years:-200}"
final_spinup_years="${final_spinup_years:-600}"
transient_years="${transient_years:--1}"
timestep="${timestep:-1}"
param_list="${param_list:-/scripts/param_list_example_kougarok}"
num_ens="${num_ens:-6}"
num_groups="${num_groups:-3}"

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
echo "Input parameter list = ${param_list}"
echo "Number of MCMC Ensembles = ${num_ens}"
echo "Number of MPI groups = ${num_groups}"
if [ ${transient_years} != -1 ]; then
  sim_years="--nyears_ad_spinup ${ad_spinup_years} --nyears_final_spinup ${final_spinup_years} \
  --nyears_transient ${transient_years}"
else
  sim_years="--nyears_ad_spinup ${ad_spinup_years} --nyears_final_spinup ${final_spinup_years}"
fi
echo " "
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
echo "Building ensemble simulations with OLMT source: "$(pwd)
echo "*****************************************************************"
echo " "
echo " "
echo "**** User OLMT run command: "
runcmd="python3 ./site_fullrun.py \
      --site ${site_code} --sitegroup ${site_group} --caseidprefix ${case_prefix} \
      ${sim_years} --tstep ${timestep} --machine docker \
      --compiler gnu --mpilib mpi-serial \
      --cpl_bypass --gswp3 \
      --model_root /E3SM \
      --caseroot /output \
      --ccsm_input /inputdata \
      --runroot /output \
      --spinup_vars \
      --parm_list ${param_list} \
      --mc_ensemble ${num_ens} \
      --nopointdata \
      --metdir /inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v2.c180716_NGEE-Grid/cpl_bypass_${site_name}-Grid \
      --domainfile /inputdata/share/domains/domain.clm/domain.lnd.1x1pt_${site_name}-GRID_navy.nc \
      --surffile /inputdata/lnd/clm2/surfdata_map/surfdata_1x1pt_${site_name}-GRID_simyr1850_c360x720_c171002.nc \
      --landusefile /inputdata/lnd/clm2/surfdata_map/landuse.timeseries_1x1pt_${site_name}-GRID_simyr1850-2015_c180423.nc \
      & sleep 10"
echo ${runcmd}
echo " "
echo " "

# create the OLMT run command
if python3 ./site_fullrun.py \
      --site ${site_code} --sitegroup ${site_group} --caseidprefix ${case_prefix} \
      ${sim_years} --tstep ${timestep} --machine docker \
      --compiler gnu --mpilib mpi-serial \
      --cpl_bypass --gswp3 \
      --model_root /E3SM \
      --caseroot /output \
      --ccsm_input /inputdata \
      --runroot /output \
      --spinup_vars \
      --parm_list ${param_list} \
      --mc_ensemble ${num_ens} \
      --ng ${num_groups} \
      --nopointdata \
      --metdir /inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v2.c180716_NGEE-Grid/cpl_bypass_${site_name}-Grid \
      --domainfile /inputdata/share/domains/domain.clm/domain.lnd.1x1pt_${site_name}-GRID_navy.nc \
      --surffile /inputdata/lnd/clm2/surfdata_map/surfdata_1x1pt_${site_name}-GRID_simyr1850_c360x720_c171002.nc \
      --landusefile /inputdata/lnd/clm2/surfdata_map/landuse.timeseries_1x1pt_${site_name}-GRID_simyr1850-2015_c180423.nc \
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
# Copy the example parameter file to the OLMT ensemble output folder
cp ${param_list} /output/cime_run_dirs/UQ/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/.
### Collapse transient simulation output into a single netCDF file
echo " "
echo " "
echo " "
echo "**** Postprocessing ELM output in:"
echo "/output/cime_run_dirs/UQ/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/"
echo " "
echo " "
cd /output/cime_run_dirs/UQ/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/
echo " "
echo "**** Concatenating netCDF output - Hang tight this will take awhile ****"
echo ${PWD}
for d in */ ; do
    echo "Post-processing: $d"
    cd /output/cime_run_dirs/UQ/${case_prefix}_${site_code}_ICB20TRCNPRDCTCBC/${d}
    ncrcat --ovr *.h0.*.nc ELM_output.nc
    chmod 777 ELM_output.nc
    echo " "
done
echo " "
echo " "
echo "**** Concatenating netCDF output: DONE ****"
echo "**** OLMT Ensemble Simulation at ${site_name}: DONE ****"
echo " "
echo " "
echo " "
sleep 2
# =======================================================================================