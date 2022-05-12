#!/bin/bash

# =======================================================================================
# CTSM-FATES create_newcase template for docker container
# --- This example builds a basic single-site case using default GSWP3 met forcing
# --- User selectable options are provided below
#
# Example usage:
# ./create_ctsm-fates_single-site_case.sh --site_name=PA-SLZ --compset=I2000Clm50FatesGs \
# --start_year='2012-01-01' --num_years=3 --run_type=startup --met_start=2010 \
# --met_end=2014 --resolution=0.9x1.25 --output_vars=output_vars.txt --output_freq=H \
# --descname=siterun --debug=FALSE
#
#
# Script details:
# The user should create a local directory to house the site forcing data directories 
# as well as the larger CESM surface and domain files needed for a site simulation. 
# Missing surface, domain, and other files will be downloaded automatically to the
# main CESM input directory.
# 
# --site_name The name of the directory containing the single-site forcing data
# --compset Desired CTSM-FATES compset to build
# --start_year What year to start the model simulation
# --num_years How many years to run the model
# --run_type Set the run type, default startup
# --met_start First year of met forcing data to use
# --met_end Last year of met forcing data to use
# ** The combination of met_start & met_end define the window of met forcing years for
#    the model simulation where 2010-2014 would be those years would be recycled over
#    the simulation period. Helpful to reduce the number of files to download in a 
#    simple test case.  Full range is 1901-2014
# --output_vars Can use this to define a text file in the /scripts/ directory
#   containing a list of model output variables to enable
# --output_freq H hourly, M monthly
# --descname Descriptive name for the model simulation.  Will be the case folder prefix
# --debug TRUE/FALSE
#
#
# TODO: Update this script to point to just the single-site directory once 
# all forcing files needed per compset and resolution are converted to single site
# inputs.
# =======================================================================================

# =======================================================================================
# DEFAULT OUTPUT VARIABLES - USED IF NOT SET AS A FLAG
default_vars='NEP','GPP','NPP','AR','HR','AGB','TLAI','ALBD','QVEGT',\
'EFLX_LH_TOT','ED_biomass','ED_bleaf','ED_balive','WIND','ZBOT','RH',\
'TBOT','PBOT','QBOT','RAIN','FSR','FSDS','FLDS'
# =======================================================================================

# =======================================================================================
# RUN SPECIFIC SETUP - USER TO MODIFY VIA CMD FLAGS

for i in "$@"
do
case $i in
    -sn=*|--site_name=*)
    site_name="${i#*=}"
    shift
    ;;
    -cs=*|--compset=*)
    compset="${i#*=}"
    shift
    ;;
    -sy=*|--start_year=*)
    start_year="${i#*=}"
    shift
    ;;
    -ny=*|--num_years=*)
    num_years="${i#*=}"
    shift
    ;;
    -rt=*|--run_type=*)
    run_type="${i#*=}"
    shift
    ;;
    -mets=*|--met_start=*)
    met_start="${i#*=}"
    shift
    ;;
    -mete=*|--met_end=*)
    met_end="${i#*=}"
    shift
    ;;
    -res=*|--resolution=*)
    resolution="${i#*=}"
    shift
    ;;
    -ov=*|--output_vars=*)
    output_vars="${i#*=}"
    shift
    ;;
    -of=*|--output_freq=*)
    output_freq="${i#*=}"
    shift
    ;;
    -dn=*|--descname=*)
    descname="${i#*=}"
    shift
    ;;
    -db=*|--debug=*)
    debug="${i#*=}"
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

# check for missing inputs and set defaults
site_name="${site_name:-PA-SLZ}"
compset="${compset:-I2000Clm50FatesGs}"
resolution="${resolution:-0.9x1.25}"
start_year="${start_year:-'2010-01-01'}"
num_years="${num_years:-2}"
rtype="${rtype:-startup}"
met_start="${met_start:-2010}"
met_end="${met_end:-2012}"
output_freq="${output_freq:-M}" # M monthly or H hourly
descname="${descname:-siterun}"
debug="${debug:-FALSE}"

# setup output variable list, either using cmd flag or defaults
if [ -z "$output_vars" ];
then
out_vars=${default_vars}
else
out_vars=$(cat "scripts/$output_vars")
out_vars="${out_vars//\\/}"
fi

# show options
export INPUTDIR=/inputdata                             # /inputdata is default
echo "Site Name = ${site_name}"
echo "DATM data source = ${INPUTDIR}/${site_name}"
echo "Model compset  = ${compset}"
echo "Resolution: "${resolution}
echo "Model simulation start year  = ${start_year}"
echo "Number of simulation years  = ${num_years}"
echo "Run type = ${rtype}"
echo "DATM_CLMNCEP_YR_START: "${met_start}
echo "DATM_CLMNCEP_YR_END: "${met_end}
echo "Selected output variables: "${out_vars}
echo "Selected output frequency: "${output_freq}
echo "Descriptive case name: "${descname}
# =======================================================================================

# =======================================================================================
# DOCKER MACHINE SPECIFIC ARGUMENTS - DO NOT CHANGE

export CATEGORY=fates           # For descriptive use in the casename
export COMPILER=gnu             # Currently only gcc compilers supported
export MODEL_SOURCE=/CTSM       # Location of ctsm hlm
export MACH=${HOSTNAME}         # This is set via --hostname=docker option
export MODEL_VERSION=CTSM-FATES # info tag
export RES=CLM_USRDAT    # 1x1 test site in the central Amazon
# =======================================================================================

# =======================================================================================
# SETUP DIRECTORY - USER SHOULD NOT NEED TO CHANGE THESE

# Switch to host land model
echo "Running with CTSM location: "${MODEL_SOURCE}
cd ${MODEL_SOURCE}/cime/scripts

# Setup githash to append to test directory name for reproducability
export CLMHASH=`cd ../../;git log -n 1 --format=%h`
export FATESHASH=`(cd ../../src/fates;git log -n 1 --format=%h)`
export GITHASH="C"${CLMHASH}"-F"${FATESHASH}
export date_var=$(date +"%Y-%m-%d_%H-%M-%S") # auto info tag

# Match the output and input directories to the docker run -v volume mount option
export CASEDIR=/output          # /output is default

# Setup build, run and output directory name
export CASENAME=${CASEDIR}/${site_name}.${descname}.${CATEGORY}.${MACH}.${compset}.${GITHASH}.${date_var}
# =======================================================================================

# =======================================================================================
# CREATE THE CASE
rm -rf ${CASENAME} # given the datetime this case dir should be unique

echo "*** start: ${date_var} "
echo "*** Building CASE: ${CASENAME} "
echo "Calling create_newcase"
./create_newcase --case=${CASENAME} --res=${RES} --compset=${compset} \
--mach=${MACH} --compiler=${COMPILER} --run-unsupported

# Change to the created case directory
echo "Changing to case directory: " ${CASENAME}
cd ${CASENAME}
# =======================================================================================

# =======================================================================================
# Setup forcing data paths and files:
# Define forcing and surfice file data for run:
export datmdata_dir=${INPUTDIR}/single_site/${site_name}/datmdata
export datm_data_root=${INPUTDIR}/single_site/${site_name}
echo "DATM root: ${datm_data_root}"
echo "DATM data forcing data directory: ${datmdata_dir}"

pattern=${datmdata_dir}/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/"domain.lnd.360x720_*"
datm_domain_lnd=( $pattern )
echo "DATM data land domain file:"
export CLM5_DATM_DOMAIN_LND=${datm_domain_lnd[0]}
echo "${CLM5_DATM_DOMAIN_LND}"

pattern=${datm_data_root}/"domain.lnd.fv${resolution}*"
domain_lnd=( $pattern )
domain_lnd_file="$(basename $domain_lnd)"
echo "Land domain file:"
export CLM5_USRDAT_DOMAIN=${domain_lnd_file[0]}
echo "CLM5 Domain File: ${CLM5_USRDAT_DOMAIN}"

pattern=${datm_data_root}/"surfdata_${resolution}_16pfts*"
surfdata=( $pattern )
surfdata_file="$(basename $surfdata)"
echo "Surface file:"
export CLM5_SURFDAT_file=${surfdata_file[0]}
echo "CLM5 Surface File: ${CLM5_SURFDAT_file}"
# =======================================================================================

# =======================================================================================
# UPDATE CASE CONFIGURATION - user to update or add as necessary
echo "*** Modifying xmls  ***"

./xmlchange RUN_TYPE=${rtype}
./xmlchange DEBUG=${debug}
./xmlchange INFO_DBUG=0
./xmlchange CALENDAR=GREGORIAN

./xmlchange RUN_STARTDATE=${start_year}
./xmlchange --id STOP_N --val ${num_years}
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id REST_N --val 1
./xmlchange --id REST_OPTION --val nyears
./xmlchange --id CLM_FORCE_COLDSTART --val on
./xmlchange --id RESUBMIT --val 0
./xmlchange --file env_run.xml --id DOUT_S_SAVE_INTERIM_RESTART_FILES --val TRUE
./xmlchange --file env_run.xml --id DOUT_S --val TRUE
./xmlchange --file env_run.xml --id DOUT_S_ROOT --val ${CASENAME}/history
./xmlchange --file env_run.xml --id RUNDIR --val ${CASENAME}/run
./xmlchange --file env_build.xml --id EXEROOT --val ${CASENAME}/bld

# domain options
./xmlchange -a CLM_CONFIG_OPTS='-nofire'
./xmlchange ATM_DOMAIN_FILE=${CLM5_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_FILE=${CLM5_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${datm_data_root}
./xmlchange LND_DOMAIN_PATH=${datm_data_root}
./xmlchange CLM_USRDAT_NAME=${site_name}
./xmlchange MOSART_MODE=NULL

# met options
./xmlchange --id DATM_CLMNCEP_YR_START --val ${met_start}
./xmlchange --id DATM_CLMNCEP_YR_END --val ${met_end}

# location of forcing and surface files. This is relative to within the container 
# after mapping the external data dir to /data
./xmlchange DIN_LOC_ROOT_CLMFORC=${datmdata_dir}
./xmlchange DIN_LOC_ROOT=${INPUTDIR}

# Optimize PE layout for run  - we may need to be careful here
# so as to make this run on a wide range of machines
# Adding in more CPUs may crash some machines
./xmlchange NTASKS_ATM=1,ROOTPE_ATM=0,NTHRDS_ATM=1
./xmlchange NTASKS_CPL=1,ROOTPE_CPL=1,NTHRDS_CPL=1
./xmlchange NTASKS_LND=1,ROOTPE_LND=3,NTHRDS_LND=1
./xmlchange NTASKS_OCN=1,ROOTPE_OCN=1,NTHRDS_OCN=1
./xmlchange NTASKS_ICE=1,ROOTPE_ICE=1,NTHRDS_ICE=1
./xmlchange NTASKS_GLC=1,ROOTPE_GLC=1,NTHRDS_GLC=1
./xmlchange NTASKS_ROF=1,ROOTPE_ROF=1,NTHRDS_ROF=1
./xmlchange NTASKS_WAV=1,ROOTPE_WAV=1,NTHRDS_WAV=1
./xmlchange NTASKS_ESP=1,ROOTPE_ESP=1,NTHRDS_ESP=1

# Set run location to case dir
./xmlchange --file env_build.xml --id CIME_OUTPUT_ROOT --val ${CASENAME}
# =======================================================================================

# =======================================================================================
echo "*** Update user_nl_clm ***"
echo " "

export CLM5_SURFDAT=${datm_data_root}/${CLM5_SURFDAT_file}
echo "CLM5 Surface File Path: ${CLM5_SURFDAT}"
if [[ $output_freq = "M" ]]; then
echo "*** Set output frequency to monthy ***"
cat >> user_nl_clm <<EOF
fsurdat = '${CLM5_SURFDAT}'
hist_empty_htapes = .true.
hist_fincl1       = ${out_vars}
hist_mfilt             = 12
hist_nhtfrq            = 0
EOF

elif [[ $output_freq = "H" ]]; then
echo "*** Set output frequency to hourly ***"
cat >> user_nl_clm <<EOF
fsurdat = '${CLM5_SURFDAT}'
hist_empty_htapes = .true.
hist_fincl1       = ${out_vars}
hist_mfilt             = 8760
hist_nhtfrq            = -1
EOF

else 
echo "*** Output frequency option not valid, defaulting to monthly ***"
cat >> user_nl_clm <<EOF
fsurdat = '${CLM5_SURFDAT}'
hist_empty_htapes = .true.
hist_fincl1       = ${out_vars}
hist_mfilt             = 12
hist_nhtfrq            = 0
EOF

fi

## define met params
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

echo "*** Build case ***"
echo " "
./case.build

echo "*** Finished building new case in CASE: ${CASENAME} ***"
echo " "
echo " "
echo " "

# MANUALLY SUBMIT CASE
echo "*****************************************************************************************************"
echo "If you built this case interactively then:"
echo "To submit the case change directory to ${CASENAME} and run ./case.submit"
echo " "
echo " "
echo "If you built this case non-interactively then change your Docker run command to:"
echo " "
echo 'docker run -t -i --hostname=docker --user $(id -u):$(id -g) --volume /path/to/host/inputs:/inputdata \
--volume /path/to/host/outputs:/output docker_image_tag' "/bin/sh -c 'cd ${CASENAME} && ./case.submit'"
echo " "
echo "Where: "
echo "/path/to/host/inputs is your host input path, such as /Volumes/data/Model_Data/cesm_input_datasets"
echo "/path/to/host/outputs is your host output path, such as ~/scratch/ctsm_fates"
echo "/path/to/host/outputs is the docker image tag on your host machine, e.g. ngeetropics/fates-ctsm-gcc650:latest"
echo " "
echo "Alternatively, you can use environmental variables to define the constants, e.g.:"
echo "export input_data=/Volumes/data/Model_Data/cesm_input_datasets"
echo "export output_dir=~/scratch/ctsm_fates"
echo "export docker_tag=ngeetropics/fates-ctsm-gcc650:latest"
echo " "
echo "And run the case using:"
echo 'docker run -t -i --hostname=docker --user $(id -u):$(id -g) --volume ${input_data}:/inputdata \
--volume ${output_dir}:/output ${docker_tag}' "/bin/sh -c 'cd ${CASENAME} && ./case.submit'"
echo "*****************************************************************************************************"
echo " "
echo " "
echo " "
# eof
