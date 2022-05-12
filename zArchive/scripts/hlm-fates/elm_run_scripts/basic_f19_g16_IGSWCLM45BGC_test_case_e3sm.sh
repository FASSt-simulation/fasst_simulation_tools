#!/bin/bash

# =======================================================================================
export date_var=$(date +%s)
export CASE_NAME=/output/f19_g16.IGSWCLM45BGC.${date_var}
cd /E3SM/cime/scripts
./create_newcase --case ${CASE_NAME} --res f19_g16 --compset IGSWCLM45BGC --mach docker --compiler gnu
cd ${CASE_NAME}
# =======================================================================================

# =======================================================================================
./xmlchange --id RUN_STARTDATE --val '1980-01-01'
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id STOP_N --val 5
./xmlchange --id DATM_CLMNCEP_YR_START --val 1980
./xmlchange --id DATM_CLMNCEP_YR_END --val 1985
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run 
./xmlchange EXEROOT=${PWD}/bld
./xmlchange DIN_LOC_ROOT_CLMFORC=/inputdata/atm/datm7
./xmlchange DIN_LOC_ROOT=/inputdata/

# startup options, spinup options
./xmlchange --id CLM_FORCE_COLDSTART --val on
./xmlchange --id CLM_ACCELERATED_SPINUP --val off

# domain options
./xmlchange -a CLM_CONFIG_OPTS='-nofire'
./xmlchange MOSART_MODE=NULL

# resource options
#./xmlchange NTASKS=1
#./xmlchange MAX_TASKS_PER_NODE=1
#./xmlchange NTASKS_LND=4,ROOTPE_LND=0 
./xmlchange NTASKS_ATM=1,ROOTPE_ATM=0,NTHRDS_ATM=1
./xmlchange NTASKS_CPL=1,ROOTPE_CPL=1,NTHRDS_CPL=1
./xmlchange NTASKS_LND=1,ROOTPE_LND=3,NTHRDS_LND=1
./xmlchange NTASKS_OCN=1,ROOTPE_OCN=1,NTHRDS_OCN=1
./xmlchange NTASKS_ICE=1,ROOTPE_ICE=1,NTHRDS_ICE=1
./xmlchange NTASKS_GLC=1,ROOTPE_GLC=1,NTHRDS_GLC=1
./xmlchange NTASKS_ROF=1,ROOTPE_ROF=1,NTHRDS_ROF=1
./xmlchange NTASKS_WAV=1,ROOTPE_WAV=1,NTHRDS_WAV=1
./xmlchange NTASKS_ESP=1,ROOTPE_ESP=1,NTHRDS_ESP=1

cd ${CASE_NAME}
# =======================================================================================

# =======================================================================================
# setup case
echo "*** Running case.setup ***"
echo " "
./case.setup

# define output variables and output frequency
cat >> user_nl_clm <<EOF
hist_empty_htapes = .true.
hist_mfilt             = 12
hist_nhtfrq            = 0
EOF

# build case
echo "*** Build case ***"
echo " "
./case.build

echo "*** Finished building new case in CASE: ${CASE_NAME} ***"
echo " "
echo " "
echo " "
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
echo "/path/to/host/outputs is the docker image tag on your host machine, e.g. fasstsimulation/elm-builds:release-v1.2.0-latest"
echo " "
echo "Alternatively, you can use environmental variables to define the constants, e.g.:"
echo "export input_data=/Volumes/data/Model_Data/cesm_input_datasets"
echo "export output_dir=~/scratch/ctsm_fates"
echo "export docker_tag=fasstsimulation/elm-builds:release-v1.2.0-latest"
echo " "
echo "And run the case using:"
echo 'docker run -t -i --hostname=docker --user $(id -u):$(id -g) --volume ${input_data}:/inputdata \
--volume ${output_dir}:/output ${docker_tag}' "/bin/sh -c 'cd ${CASE_NAME} && ./case.submit'"
echo "*****************************************************************************************************"
echo " "
echo " "
echo " "
# eof