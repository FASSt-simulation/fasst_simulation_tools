#!/bin/bash

echo $HOME
# =======================================================================================
# ELM create_newcase template for docker container
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
    -of=*|--output_freq=*)
    output_freq="${i#*=}"
    shift
    ;;
    -rt=*|--run_type=*)
    run_type="${i#*=}"
    shift # past argument=value
    ;;
    -so=*|--stop_option=*)
    stop_option="${i#*=}"
    shift # past argument=value
    ;;
    -mets=*|--met_start=*)
    met_start="${i#*=}"
    shift # past argument with no value
    ;;
    -mete=*|--met_end=*)
    met_end="${i#*=}"
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
    -com=*|--compset=*)
    compset="${i#*=}"
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
met_start="${met_start:-1985}"
met_end="${met_end:-2015}"
domain_lnd="${domain_lnd:-domain.lnd.fv0.9x1.25_gx1v6.090309}"
surfdata_map="${surfdata_map:-surfdata_0.9x1.25_simyr2000_c180404}"
compset="${compset:-I1850GSWELMBGC}"
output_freq="${output_freq:-M}" # M monthly or H hourly
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
#echo "Resolution: "${resolution}
echo "Model simulation start year  = ${start_year}"
echo "Number of simulation years  = ${num_years}"
echo "Run type = ${run_type}"
echo "DATM_CLMNCEP_YR_START: "${met_start}
echo "DATM_CLMNCEP_YR_END: "${met_end}
echo "Selected output variables: "${out_vars}
echo "Selected output frequency: "${output_freq}
#echo "Descriptive case name: "${descname}
echo " "
# =======================================================================================

# =======================================================================================
# Create a new case
export MODEL_SOURCE=${model_source}
#export date_var=$(date +%s)
export CASEROOT=${case_root}
export SITE_NAME=${site_name}
export MODEL_VERSION=ELM
#export RESOLUTION=${resolution}
export COMPSET=${compset}
export CASE_NAME=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"final_spinup"
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
./xmlchange RUN_TYPE=${run_type}
./xmlchange DEBUG=${debug}
./xmlchange INFO_DBUG=0
./xmlchange PIO_TYPENAME=netcdf
#./xmlchange PIO_VERSION=2
#./xmlchange CALENDAR=GREGORIAN
#./xmlchange RUN_STARTDATE=${start_year}
./xmlchange STOP_N=${num_years}
./xmlchange STOP_OPTION=${stop_option}
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=${num_years}   # this should be a user selectable option
./xmlchange RESUBMIT=0 # this should be a user selectable option
./xmlchange RUN_REFDATE=0201-01-01 # restart ref file date. probably shouldnt be hard coded
./xmlchange SAVE_TIMING=FALSE

# build options - may want to set some of these up, but would depend on the COMPSET being used
./xmlchange --id ELM_BLDNML_OPTS --val '-bgc bgc -nutrient cn -nutrient_comp_pathway rd  -soil_decomp ctc -methane -nitrif_denitrif'
./xmlchange EXEROOT=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup"/bld  # where to put the compiled exe file

# met options
#/xmlchange DATM_CLMNCEP_YR_START=${met_start}
#./xmlchange DATM_CLMNCEP_YR_END=${met_end}
./xmlchange DIN_LOC_ROOT_CLMFORC=${datmdata_dir}
./xmlchange DIN_LOC_ROOT=${INPUTDIR}

# startup options, spinup options
./xmlchange ELM_FORCE_COLDSTART=off
./xmlchange ELM_ACCELERATED_SPINUP=off

# domain options
#./xmlchange -a ELM_CONFIG_OPTS='-nofire'
./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${datm_data_root}
./xmlchange LND_DOMAIN_PATH=${datm_data_root}
./xmlchange ELM_USRDAT_NAME=${site_name}
./xmlchange MOSART_MODE=NULL

# output options
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT=${CASE_NAME}/history
./xmlchange RUNDIR=${CASE_NAME}/run

#./xmlchange ATM_NCPL=24
./xmlchange NTASKS=1

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASE_NAME}
# =======================================================================================

# =======================================================================================
# Setup and build ELM case
cd ${CASE_NAME}
echo $PWD

echo "*** Update user_nl_elm ***"
echo " "

#export CLM5_SURFDAT=${datm_data_root}/${CLM5_SURFDAT_file}
export HIST_REST_DIR=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup/history/rest/0201-01-01-00000"
export HIST_REST_FILE=${HIST_REST_DIR}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup.elm.r.0201-01-01-00000.nc"

echo "CLM5 Surface File Path: ${ELM_SURFDAT_file}"
echo "*** Set output frequency to monthy ***"
cat >> user_nl_elm <<EOF
finidat = '${HIST_REST_FILE}'
fsurdat = '${ELM_SURFDAT_file}'
hist_mfilt = 1
hist_nhtfrq = -175200
nyears_ad_carbon_only   = 25
spinup_mortality_factor = 10
!stream_fldfilename_ndep = '/inputdata/lnd/clm2/ndepdata/fndep_clm_rcp4.5_simyr1849-2106_1.9x2.5_c100428.nc'
!co2_file = '/inputdata/atm/datm7/CO2/fco2_datm_rcp4.5_1765-2500_c130312.nc'
!aero_file = '/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_rcp4.5_monthly_1849-2104_0.9x1.25_c100407.nc'
! Include this line to use variable soil depths:
!use_var_soil_thick = .TRUE.
EOF

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

./xmlchange BUILD_COMPLETE=TRUE