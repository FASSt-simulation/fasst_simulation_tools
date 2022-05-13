#!/bin/bash

echo $HOME
# =======================================================================================
# ELM create_newcase template for docker container
# --- This example builds a basic single-site case using default GSWP3 met forcing,
#     created using interim met forcing script "create_GSWP3.0.5d.v1_single_point_forcing_data_elm.py"
# --- User selectable options are provided below
# 
# ELM version: 2.0.0
# Script details:
# =======================================================================================

# =======================================================================================
# DEFAULT OUTPUT VARIABLES - USED IF NOT SET AS A FLAG
default_vars='NEP','GPP','NPP','AR','HR','AGB','TLAI','ALBD','QVEGT',\
'EFLX_LH_TOT','WIND','ZBOT','RH','TBOT','PBOT','QBOT','RAIN','FSR','FSDS','FLDS'
# =======================================================================================

# =======================================================================================
# get the user inputs
for i in "$@"
do
case $i in
    -ms=*|--model_source=*)
    model_source="${i#*=}"
    shift
    ;;
    -cr=*|--case_root=*)
    case_root="${i#*=}"
    shift # past argument=value
    ;;
    -sn=*|--site_name=*)
    site_name="${i#*=}"
    shift # past argument=value
    ;;
    -sy=*|--start_year=*)
    start_year="${i#*=}"
    shift # past argument=value
    ;;
    -ny=*|--num_years=*)
    num_years="${i#*=}"
    shift # past argument=value
    ;;
    -ov=*|--output_vars=*)
    output_vars="${i#*=}"
    shift # past argument=value
    ;;
    -rt=*|--run_type=*)
    run_type="${i#*=}"
    shift # past argument=value
    ;;
    -so=*|--stop_option=*)
    stop_option="${i#*=}"
    shift # past argument=value
    ;;
    -com=*|--compset=*)
    compset="${i#*=}"
    shift # past argument with no value
    ;;
    -dl=*|--domain_lnd=*)
    domain_lnd="${i#*=}"
    shift # past argument with no value
    ;;
    -sm=*|--surfdata_map=*)
    surfdata_map="${i#*=}"
    shift # past argument with no value
    ;;
    -rmach=*|--rmachine=*)
    rmachine="${i#*=}"
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done
# =======================================================================================

# =======================================================================================
# check for missing inputs and set defaults
model_source="${model_source:-/E3SM}"
case_root="${case_root:-/output}"
site_name="${site_name:-US-xTA}"
start_year="${start_year:-'1985-01-01'}"
num_years="${num_years:-5}"
output_vars="${output_vars:-/scripts/output_vars.txt}"
run_type="${run_type:-startup}"
stop_option="${stop_option:-nyears}"
# add rest options here too
domain_lnd="${domain_lnd:-domain.lnd.fv0.9x1.25_gx1v6.090309}"
surfdata_map="${surfdata_map:-surfdata_0.9x1.25_simyr2000_c180404}"
compset="${compset:-I1850GSWELMBGC}"
#IGSWELMBGC
#ICB1850CNPRDCTCBC
#I1850GSWELMBGC
#I20TRCRUELMBGC
#output_freq="${output_freq:-M}" # M monthly or H hourly
debug="${debug:-FALSE}"
rmachine="${rmachine:-docker}"
#descname="${descname:-siterun}"
#resolution="${resolution:-0.9x1.25}"

# setup output variable list, either using cmd flag or defaults
if [ -z "$output_vars" ];
then
out_vars=${default_vars}
else
out_vars=$(cat "$output_vars")
out_vars="${out_vars//\\/}"
fi

echo "Selected output variables: "${out_vars}
echo " "
echo " "
# =======================================================================================

# =======================================================================================
# show options
export INPUTDIR=/inputdata
echo "Site Name = ${site_name}"
echo "DATM data source = ${INPUTDIR}/${site_name}"
echo "Model compset  = ${compset}"
echo "Model simulation start year  = ${start_year}"
echo "Number of simulation years  = ${num_years}"
echo "Run type = ${run_type}"
echo "Selected output variables: "${out_vars}
echo " "
# =======================================================================================

# =======================================================================================
# Create a new case
export MODEL_SOURCE=${model_source}
export CASEROOT=${case_root}
export SITE_NAME=${site_name}
export MODEL_VERSION=ELM
export COMPSET=${compset}
export CASE_NAME=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup"
export RUN_MACHINE=${rmachine}

echo " "
echo "*** Removing old case, if exists ***"
rm -rf ${CASE_NAME}
echo " "
cd /E3SM/cime/scripts
echo "Running create_newcase in: ${PWD}"
./create_newcase --case ${CASE_NAME} --res ELM_USRDAT --compset ${COMPSET} --mach ${RUN_MACHINE} --compiler gnu
cd ${CASE_NAME}
echo " "
echo "${PWD}"
echo " "
# =======================================================================================

# =======================================================================================
# Setup forcing data paths and files:
# Define forcing and surfice file data for run:
echo " "
export datmdata_dir=${INPUTDIR}/elm_single_point/${site_name}/datmdata
export datm_data_root=${INPUTDIR}/elm_single_point/${site_name}
echo "DATM root: ${datm_data_root}"
echo "DATM data forcing data directory: ${datmdata_dir}"

datm_domain_lnd=${datmdata_dir}/"domain.lnd.360x720_gswp3.0v1.c170606.nc"
export ELM_DATM_DOMAIN_LND=${datm_domain_lnd[0]}
echo "DATM land domain file: ${ELM_DATM_DOMAIN_LND}"

pattern=${datm_data_root}/"${domain_lnd}*"
domain_lnd=( $pattern )
domain_lnd_file=$(basename $pattern)
echo "Land domain file:"
echo "${domain_lnd_file[0]}"
export ELM_USRDAT_DOMAIN=${domain_lnd_file[0]}

pattern=${datm_data_root}/"${surfdata_map}*"
surfdata=( $pattern )
#surfdata_file="$(basename $surfdata)"
echo "Surface file:"
echo "${surfdata[0]}"
export ELM_SURFDAT_file=${surfdata[0]}
# =======================================================================================

# =======================================================================================
# UPDATE CASE CONFIGURATION
echo " "
echo "*** Modifying xmls  ***"
echo "RUN_TYPE=${run_type}"

# run options
./xmlchange ELM_USRDAT_NAME=${site_name}
./xmlchange RUN_TYPE=${run_type}
./xmlchange DEBUG=${debug}
./xmlchange INFO_DBUG=0
./xmlchange PIO_TYPENAME=netcdf
#./xmlchange CALENDAR=GREGORIAN
./xmlchange RUN_STARTDATE=${start_year}
./xmlchange STOP_N=${num_years}
./xmlchange STOP_OPTION=${stop_option}
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=${num_years}   # this should be a user selectable option
./xmlchange RESUBMIT=0 # this should be a user selectable option

# build options - may want to set some of these up, but would depend on the COMPSET being used
./xmlchange --id ELM_BLDNML_OPTS --val '-bgc bgc -nutrient cn -nutrient_comp_pathway rd  -soil_decomp ctc -methane'
./xmlchange EXEROOT=${CASE_NAME}/bld  # where to put the compiled exe file

# startup options, spinup options
./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_ACCELERATED_SPINUP=on

# met options
./xmlchange DIN_LOC_ROOT_CLMFORC=${datmdata_dir}
./xmlchange DIN_LOC_ROOT=${INPUTDIR}

# domain options
#./xmlchange -a ELM_CONFIG_OPTS='-nofire'
./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${datm_data_root}
./xmlchange LND_DOMAIN_PATH=${datm_data_root}
./xmlchange MOSART_MODE=NULL

# output options
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT=${CASE_NAME}/history
./xmlchange RUNDIR=${CASE_NAME}/run

./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT=${CASE_NAME}/history
./xmlchange RUNDIR=${CASE_NAME}/run

# Optimize PE layout for run  - we may need to be careful here
# so as to make this run on a wide range of machines
# Adding in more CPUs may crash some machines
#./xmlchange NTASKS_ATM=1,ROOTPE_ATM=0,NTHRDS_ATM=1
#./xmlchange NTASKS_CPL=1,ROOTPE_CPL=1,NTHRDS_CPL=1
#./xmlchange NTASKS_LND=1,ROOTPE_LND=3,NTHRDS_LND=1
#./xmlchange NTASKS_OCN=1,ROOTPE_OCN=1,NTHRDS_OCN=1
#./xmlchange NTASKS_ICE=1,ROOTPE_ICE=1,NTHRDS_ICE=1
#./xmlchange NTASKS_GLC=1,ROOTPE_GLC=1,NTHRDS_GLC=1
#./xmlchange NTASKS_ROF=1,ROOTPE_ROF=1,NTHRDS_ROF=1
#./xmlchange NTASKS_WAV=1,ROOTPE_WAV=1,NTHRDS_WAV=1
#./xmlchange NTASKS_ESP=1,ROOTPE_ESP=1,NTHRDS_ESP=1

# or to use only a single core per simulation
./xmlchange NTASKS=1
#./xmlchange NTASKS_LND=1,ROOTPE_LND=3,NTHRDS_LND=1

# or none set and that would default to 
# run command is mpirun  -np 1  -npernode 4 
# because of the options set in config_machines.xml

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASE_NAME}
# =======================================================================================

# =======================================================================================
# Setup and build ELM case
cd ${CASE_NAME}
echo $PWD

echo "*** Update user_nl_elm ***"
echo " "

echo "ELM Surface File Path: ${ELM_SURFDAT_file}"
echo "*** Configure user_nl_elm for AD spinup ***"
cat >> user_nl_elm <<EOF
!paramfile =/path/to/custom/paramfile.nc
finidat = ''
fsurdat = '${ELM_SURFDAT_file}'
nyears_ad_carbon_only   = 25
spinup_mortality_factor = 10
!co2_file = '/inputdata/atm/datm7/CO2/fco2_datm_rcp4.5_1765-2500_c130312.nc'
!aero_file = '/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_rcp4.5_monthly_1849-2104_0.9x1.25_c100407.nc'
!stream_fldfilename_ndep = '/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
! Include this line to use variable soil depths:
!use_var_soil_thick = .TRUE.

! History file controls
hist_mfilt = 1, 1
hist_nhtfrq = -175200, -175200
EOF
#!hist_fincl1       = ${out_vars}
#!hist_dov2xy = .true., .false.
#!hist_fincl2 = 'CWDC_vr','CWDN_vr','CWDP_vr','SOIL2C_vr','SOIL2N_vr','SOIL2P_vr','SOIL3C_vr','SOIL3N_vr',\
#!'SOIL3P_vr','DEADSTEMC','DEADSTEMN','DEADSTEMP','DEADCROOTC','DEADCROOTN','DEADCROOTP','LITR3C_vr',\
#!'LITR3N_vr','LITR3P_vr','LEAFC','TOTVEGC','TLAI','SOIL4C_vr','SOIL4N_vr','SOIL4P_vr'

## Configure met params
echo " "
echo "*** Update met forcing options ***"
echo " "
cat >> user_nl_datm <<EOF
mapalgo = 'nn', 'nn', 'nn'
taxmode = "cycle", "cycle", "cycle"
EOF

#./cesm_setup
echo "*** Running case.setup ***"
echo " "
./case.setup

echo "*** Run preview_namelists ***"
echo " "
./preview_namelists

# build case
echo "*** Build case ***"
echo " "
./case.build

echo "*** Finished building new case in CASE: ${CASE_NAME} ***"
echo " "
echo " "
echo " "
# =======================================================================================

# =======================================================================================
# MANUALLY SUBMIT CASE
echo "*****************************************************************************************************"
echo "If you built this case interactively then:"
echo "To submit the case change directory to ${CASE_NAME} and run ./case.submit"
echo " "
echo " "
echo "If you built this case non-interactively then change your Docker run command to:"
echo " "
echo 'docker run -t -i --hostname=docker --user $(id -u):$(id -g) --volume /path/to/host/inputs:/inputdata \
--volume /path/to/host/outputs:/output docker_image_tag' "/bin/sh -c 'cd ${CASE_NAME} && ./case.submit'"
echo " "
echo "Where: "
echo "/path/to/host/inputs is your host input path, such as /Volumes/data/Model_Data/cesm_input_datasets"
echo "/path/to/host/outputs is your host output path, such as ~/scratch/ctsm_fates"
echo "/path/to/host/outputs is the docker image tag on your host machine, e.g. fasstsimulation/ctsm-builds:ctsm-release-clm5.0.18"
echo " "
echo "Alternatively, you can use environmental variables to define the constants, e.g.:"
echo "export input_data=/Volumes/data/Model_Data/cesm_input_datasets"
echo "export output_dir=~/scratch/ctsm_fates"
echo "export docker_tag=fasstsimulation/ctsm-builds:ctsm-release-clm5.0.18"
echo " "
echo "And run the case using:"
echo 'docker run -t -i --hostname=docker --user $(id -u):$(id -g) --volume ${input_data}:/inputdata \
--volume ${output_dir}:/output ${docker_tag}' "/bin/sh -c 'cd ${CASE_NAME} && ./case.submit'"
echo "*****************************************************************************************************"
echo " "
echo " "
echo " "
# =======================================================================================
# eof