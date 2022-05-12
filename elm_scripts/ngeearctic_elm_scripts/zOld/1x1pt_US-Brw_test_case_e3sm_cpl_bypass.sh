#!/bin/bash
# =======================================================================================
#
# ELM version: 1.2.0
#./1x1pt_US-Brw_I1850CNPRDCTCBC_test_case_e3sm.sh --case_root=/output \
#--site_name=1x1_US-Brw --start_year='1985-01-01' --num_years=6 \
#--output_vars=output_vars.txt --met_start=1985 --met_end=2015 \
#--resolution=CLM_USRDAT --compset=I1850CNPRDCTCBC
#
# =======================================================================================

echo $PWD

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
    -mets=*|--met_start=*)
    met_start="${i#*=}"
    shift # past argument with no value
    ;;
    -mete=*|--met_end=*)
    met_end="${i#*=}"
    shift # past argument with no value
    ;;
    -com=*|--compset=*)
    compset="${i#*=}"
    shift # past argument with no value
    ;;
    -res=*|--resolution=*)
    resolution="${i#*=}"
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
output_vars="${output_vars:-/scripts/output_vars.txt}"
run_type="${run_type:-startup}"
stop_option="${stop_option:-nyears}"
# add rest options here too
met_start="${met_start:-1985}"
met_end="${met_end:-2015}"
resolution="${resolution:-CLM_USRDAT}"
compset="${compset:-I1850CNPRDCTCBC}"

# get the output vars from the file
out_vars=$(cat "$output_vars")
out_vars="${out_vars//\\/}"

echo "Selected output variables: "${out_vars}
echo " "
echo " "
# =======================================================================================

# =======================================================================================
# Create a new case
export MODEL_SOURCE=${model_source}
export date_var=$(date +%s)
export CASEROOT=${case_root}
export SITE_NAME=${site_name}
export MODEL_VERSION=ELM
export RESOLUTION=${resolution}
export COMPSET=${compset}
export CASE_NAME=${CASEROOT}/${SITE_NAME}.${MODEL_VERSION}.${COMPSET}.${date_var}

cd /E3SM/cime/scripts
./create_newcase --case ${CASE_NAME} --res ${RESOLUTION} --compset ${COMPSET} --mach docker --compiler gnu
cd ${CASE_NAME}
# =======================================================================================

# =======================================================================================
echo "*** Modifying xmls  ***"
echo "RUN_TYPE=${run_type}"

# run options
./xmlchange RUN_TYPE=${run_type}
./xmlchange DATM_MODE=CLM1PT
./xmlchange RUN_STARTDATE=${start_year}
./xmlchange DATM_CLMNCEP_YR_START=${met_start}
./xmlchange DATM_CLMNCEP_YR_END=${met_end}
#
# cant use ELM without v2 or the custom NGEE Arctic version
#./xmlchange ELM_USRDAT_NAME=1x1pt_US-Brw
#./xmlchange ELM_FORCE_COLDSTART=on
#./xmlchange ELM_ACCELERATED_SPINUP=on
#
./xmlchange CLM_USRDAT_NAME=${site_name}
./xmlchange CLM_FORCE_COLDSTART=on
./xmlchange CLM_ACCELERATED_SPINUP=on
./xmlchange --id CLM_BLDNML_OPTS --val '-bgc bgc -nutrient cn -nutrient_comp_pathway rd  -soil_decomp ctc -methane -nitrif_denitrif'
./xmlchange STOP_OPTION=${stop_option}
./xmlchange STOP_N=${num_years}
./xmlchange REST_OPTION=nyears
./xmlchange REST_N=2
./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
./xmlchange DOUT_S=TRUE

# domain options
#./xmlchange -a CLM_CONFIG_OPTS='-nofire'
#./xmlchange MOSART_MODE=NULL

# build and input file options
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run
./xmlchange EXEROOT=${PWD}/bld
./xmlchange DIN_LOC_ROOT_CLMFORC=/inputdata/atm/datm7
./xmlchange DIN_LOC_ROOT=/inputdata/
./xmlchange DOUT_S_ROOT=${PWD}/history

# resource options
./xmlchange NTASKS=1
#./xmlchange MAX_TASKS_PER_NODE=1
#./xmlchange NTASKS_LND=4,ROOTPE_LND=0 

#./xmlchange NTASKS_ATM=1,ROOTPE_ATM=0,NTHRDS_ATM=1
#./xmlchange NTASKS_CPL=1,ROOTPE_CPL=1,NTHRDS_CPL=1
#./xmlchange NTASKS_LND=1,ROOTPE_LND=3,NTHRDS_LND=1
#./xmlchange NTASKS_OCN=1,ROOTPE_OCN=1,NTHRDS_OCN=1
#./xmlchange NTASKS_ICE=1,ROOTPE_ICE=1,NTHRDS_ICE=1
#./xmlchange NTASKS_GLC=1,ROOTPE_GLC=1,NTHRDS_GLC=1
#./xmlchange NTASKS_ROF=1,ROOTPE_ROF=1,NTHRDS_ROF=1
#./xmlchange NTASKS_WAV=1,ROOTPE_WAV=1,NTHRDS_WAV=1
#./xmlchange NTASKS_ESP=1,ROOTPE_ESP=1,NTHRDS_ESP=1

cd ${CASE_NAME}
echo $PWD
# =======================================================================================

# =======================================================================================
# setup case
echo "*** Running case.setup ***"
echo " "
./case.setup

# define output variables and output frequency
#cat >> user_nl_clm <<EOF
#hist_empty_htapes = .true.
#hist_mfilt             = 8760
#hist_nhtfrq            = -1
#EOF
#hist_empty_htapes = .false. ! If true, turns off default history output (of everything at subgrid level. If false, first file is defaults
#hist_dov2xy = .true., .false. ! True means subgrid-level output, false means patch (PFT) level output
#hist_nhtfrq = 0, 0 ! Output frequency. 0 is monthly, -24 is daily, 1 is timestep
#hist_mfilt  = 12 12 ! History file writing frequency: number of points from hist_nhtfrq
#hist_avgflag_pertape = 'A', 'A', 'A' ! A for averaging, I for instantaneous
#!flanduse_timeseries = '/lustre/or-hydra/cades-ccsi/proj-shared/project_acme/cesminput_ngee/lnd/clm2/surfdata_map/landuse.timeseries_51x63pt_kougarok-NGEE_TransA_simyr1850_c181115-sub12.nc'
#!flanduse_timeseries = '/lustre/or-hydra/cades-ccsi/proj-shared/project_acme/cesminput_ngee/lnd/clm2/surfdata_map/landuse.timeseries_51x63pt_kougarok-NGEE_TransA_simyr1850_c181115default.nc'
#! Include this line to use variable soil depths:
#use_var_soil_thick = .TRUE.

# define output variables and output frequency
echo "*** Update user_nl_clm ***"
echo " "
cat >> user_nl_clm <<EOF
!paramfile =/path/to/custom/paramfile.nc
hist_empty_htapes       = .true.
hist_fincl1             = ${out_vars}
hist_mfilt              = 8760
hist_nhtfrq             = -1
metdata_type            = 'gswp3'
metdata_bypass          = '/inputdata/atm/datm7/1x1pt_US-Brw/cpl_bypass_GSWP3'
aero_file               = '/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_monthly_1850_mean_1.9x2.5_c090803.nc'
CO2_file                = '/inputdata/atm/datm7/CO2/fco2_datm_1765-2007_c100614.nc'
nyears_ad_carbon_only   = 25
spinup_mortality_factor = 10
! Include this line to use variable soil depths:
!use_var_soil_thick = .TRUE.
EOF

# Bypass the coupler
echo "*** Invoking coupler bypass ***"
echo " "
sed -i 's|CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU|CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU -DCPL_BYPASS|g' Macros.make
sed -i 's|set(CPPDEFS "${CPPDEFS}  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU")|set(CPPDEFS "${CPPDEFS}  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU -DCPL_BYPASS")|g' Macros.cmake

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