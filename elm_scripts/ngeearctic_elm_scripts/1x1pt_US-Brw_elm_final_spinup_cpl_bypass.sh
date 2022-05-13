#!/bin/bash
# =======================================================================================
#
# ELM version: 1.2.0
#./1x1pt_US-Brw_elm_final_spinup_cpl_bypass.sh --case_root=/output \
#--site_name=1x1_US-Brw --start_year='0001-01-01' --num_years=250 --num_rest_years=5 \
#--run_ref_date=0251-01-01 --output_vars=/scripts/output_vars.txt --output_freq=H \
#--compset=ICB1850CNPRDCTCBC --rmachine=docker
#
# =======================================================================================

# =======================================================================================
echo $PWD
echo $HOME

# DEFAULT OUTPUT VARIABLES - USED IF NOT SET AS A FLAG
default_vars='NEP','GPP','NPP','AR','HR','AGB','TLAI','ALBD','QVEGT',\
'EFLX_LH_TOT','WIND','ZBOT','RH','TBOT','PBOT','QBOT','RAIN','FSR','FSDS','FLDS'
# !!! Do we want to use something like this to input desired output variables for all 
# model run stages?? !!! We could use something like this to update different hist 
# outputs
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
    -nrest=*|--num_rest_years=*)
    num_rest_years="${i#*=}"
    shift # past argument=value
    ;;
    -rref=*|--run_ref_date=*)
    run_ref_date="${i#*=}"
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
#    -mets=*|--met_start=*)
#    met_start="${i#*=}"
#    shift # past argument with no value
#    ;;
#    -mete=*|--met_end=*)
#    met_end="${i#*=}"
#    shift # past argument with no value
#    ;;
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
site_name="${site_name:-US-Brw}"
start_year="${start_year:-'1985-01-01'}"
num_years="${num_years:-5}"
num_rest_years="${num_rest_years:-5}"
run_ref_date="${run_ref_date:-0201-01-01}"
output_vars="${output_vars:-/scripts/output_vars.txt}"
run_type="${run_type:-startup}"
stop_option="${stop_option:-nyears}"
# add rest options here too
met_start="${met_start:-1901}"
met_end="${met_end:-2014}"
resolution="${resolution:-CLM_USRDAT}"
compset="${compset:-ICB1850CNPRDCTCBC}"
output_freq="${output_freq:-H}" # M monthly or H hourly
debug="${debug:-FALSE}"
rmachine="${rmachine:-docker}"

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
echo "Retart file frequency  = ${num_rest_years}"
echo "Run type = ${run_type}"
echo "DATM_CLMNCEP_YR_START: "${met_start}
echo "DATM_CLMNCEP_YR_END: "${met_end}
echo "Selected output variables: "${out_vars}
echo "Selected output frequency: "${output_freq}
echo "Selected machine: "${rmachine}
echo "Debug: "${debug}
#echo "Descriptive case name: "${descname}
echo " "
# =======================================================================================

# =======================================================================================
# Create a new case
export MODEL_SOURCE=${model_source}
export CASEROOT=${case_root}
export SITE_NAME=${site_name}
export MODEL_VERSION=ELM
export COMPSET=${compset}
export CASE_NAME=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"final_spinup"
export RUN_MACHINE=${rmachine}

echo " "
echo "*** Removing old case, if exists ***"
rm -rf ${CASE_NAME}
echo " "
cd /E3SM/cime/scripts
echo "Running create_newcase in: ${PWD}"
./create_newcase --case ${CASE_NAME} --res CLM_USRDAT --compset ${COMPSET} --mach ${RUN_MACHINE} --compiler gnu
cd ${CASE_NAME}
echo " "
echo "${PWD}"
echo " "
# =======================================================================================

# =======================================================================================
# UPDATE CASE CONFIGURATION
echo " "
echo "*** Modifying xmls  ***"
echo "RUN_TYPE=${run_type}"

# run options
#./xmlchange DATM_MODE=CLM1PT
./xmlchange CLM_USRDAT_NAME=${site_name}
./xmlchange RUN_TYPE=${run_type}
./xmlchange DEBUG=${debug}
./xmlchange INFO_DBUG=0
./xmlchange PIO_TYPENAME=netcdf
#./xmlchange CALENDAR=GREGORIAN
./xmlchange RUN_STARTDATE=${start_year}
./xmlchange STOP_N=${num_years}
./xmlchange STOP_OPTION=${stop_option}
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=${num_rest_years}
./xmlchange RESUBMIT=0 # this should be a user selectable option
./xmlchange RUN_REFDATE=${run_ref_date}

# build options - may want to set some of these up, but would depend on the COMPSET being used
./xmlchange --id CLM_BLDNML_OPTS --val '-bgc bgc -nutrient cn -nutrient_comp_pathway rd  -soil_decomp ctc -methane -nitrif_denitrif'
#./xmlchange EXEROOT=${CASE_NAME}/bld  # where to put the compiled exe file
./xmlchange EXEROOT=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup"/bld
# probably shouldnt be hardcoded like this

# startup options, spinup options
./xmlchange CLM_FORCE_COLDSTART=off
./xmlchange CLM_ACCELERATED_SPINUP=off

# met options
#./xmlchange DATM_CLMNCEP_YR_START=${met_start}
#./xmlchange DATM_CLMNCEP_YR_END=${met_end}
./xmlchange DIN_LOC_ROOT_CLMFORC=/inputdata/atm/datm7
./xmlchange DIN_LOC_ROOT=/inputdata/

# output options
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE
./xmlchange DOUT_S_ROOT=${CASE_NAME}/history
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange DOUT_S_ROOT=${PWD}/history

# domain options
#./xmlchange -a ELM_CONFIG_OPTS='-nofire'
./xmlchange MOSART_MODE=NULL

# PIO options - do we want to have more than 1 CPU for the land model?
./xmlchange NTASKS=1

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASE_NAME}
# =======================================================================================

# =======================================================================================
# Setup and build ELM case
cd ${CASE_NAME}
echo $PWD

echo "*** Update user_nl_clm ***"
echo " "

# Setup previous runs final restart file as the finidat for the final spinup run
# may need to think about how we code these paths
export HIST_REST_DIR=${CASEROOT}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup/history/rest/"${run_ref_date}"-00000"
export HIST_REST_FILE=${HIST_REST_DIR}/${SITE_NAME}_${MODEL_VERSION}_${COMPSET}_"ad_spinup.clm2.r."${run_ref_date}"-00000.nc"

# if hourly selected - need to update this area to be H or not
if [[ $output_freq = "H" ]]; then
echo "*** Set output frequency to monthy ***"
cat >> user_nl_clm <<EOF
!paramfile =/path/to/custom/paramfile.nc
finidat                 = '${HIST_REST_FILE}'
nyears_ad_carbon_only   = 25
spinup_mortality_factor = 10
metdata_type            = 'gswp3'
metdata_bypass          = '/inputdata/atm/datm7/1x1pt_US-Brw/cpl_bypass_GSWP3'
aero_file               = '/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_monthly_1850_mean_1.9x2.5_c090803.nc'
CO2_file                = '/inputdata/atm/datm7/CO2/fco2_datm_1765-2007_c100614.nc'
! Include this line to use variable soil depths:
!use_var_soil_thick = .TRUE.

! History file controls
!hist_empty_htapes = .false. 
! If true, turns off default history output (of everything at subgrid level. If false, first file is defaults (need to account for that in subsequent controls
hist_mfilt             = 8760
hist_nhtfrq            = -1
!**hourly output slows down run significantly. perhaps not useful for AD spinup
EOF
#!hist_fincl1       = ${out_vars}
#!hist_fincl2 = 'LEAFC','FROOTC','WOODC','LIVECROOTC','TLAI','CPOOL','STORVEGC','STORVEGN','LEAFN','FROOTN','LIVECROOTN','LIVESTEMC','LIVESTEMN',
#!              'DEADCROOTC','DEADCROOTN','DEADSTEMC','DEADSTEMN','TOTVEGC','TOTVEGN','GPP','NPP','HTOP','AGNPP','BGNPP'
#!              'LEAF_MR','FROOT_MR','LIVESTEM_MR','LIVECROOT_MR','MR','VCMAX25TOP','GR','AVAILC','PLANT_CALLOC','EXCESS_CFLUX','XSMRPOOL_RECOVER','XSMRPOOL','CPOOL'
#!hist_dov2xy = .true., .false. ! True means subgrid-level output, false means patch (PFT) level output
#!hist_nhtfrq = 0, -24 ! Output frequency. 0 is monthly, -24 is daily, 1 is timestep
#!hist_mfilt  = 365 365 ! History file writing frequency: number of points from hist_nhtfrq
#!hist_avgflag_pertape = 'A', 'A', 'A' ! A for averaging, I for instantaneous

#elif [[ $output_freq = "H" ]]; then

elif [[ $output_freq = "FAST" ]]; then
#else 
echo "*** Setting default output frequency ***"
cat >> user_nl_clm <<EOF
!paramfile =/path/to/custom/paramfile.nc
finidat                 = '${HIST_REST_FILE}'
nyears_ad_carbon_only   = 25
spinup_mortality_factor = 10
metdata_type            = 'gswp3'
metdata_bypass          = '/inputdata/atm/datm7/1x1pt_US-Brw/cpl_bypass_GSWP3'
aero_file               = '/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_monthly_1850_mean_1.9x2.5_c090803.nc'
CO2_file                = '/inputdata/atm/datm7/CO2/fco2_datm_1765-2007_c100614.nc'
! Include this line to use variable soil depths:
!use_var_soil_thick = .TRUE.

! History file controls
hist_mfilt              = 1, 1
hist_nhtfrq             = -175200, -175200
EOF
# what output variables should we have for the spinup case? what is the optimal config?
# we should also allow for the user to input a custom parameter file

#!paramfile =/path/to/custom/paramfile.nc
#!finidat = ''
#!hist_fincl1       = ${out_vars}
#!hist_mfilt = 1, 1
#!hist_nhtfrq = -175200, -175200
#!hist_dov2xy = .true., .false.
#!nyears_ad_carbon_only   = 25
#!spinup_mortality_factor = 10
#! Include this line to use variable soil depths:
#!use_var_soil_thick = .TRUE.

fi # end if/else

echo "*** Running case.setup ***"
echo " "
./case.setup
echo " "

#./cesm_setup
echo "*** Running case.setup ***"
echo " "
./case.setup
echo " "

# set build complete to re-use already compiled model
./xmlchange BUILD_COMPLETE=TRUE

echo " "
echo " "
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