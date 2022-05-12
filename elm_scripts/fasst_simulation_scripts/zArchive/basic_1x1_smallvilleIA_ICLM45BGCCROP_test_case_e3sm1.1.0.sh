#!/bin/bash
export date_var=$(date +%s)
export CASE_NAME=/output/1x1_smallvilleIA.ICLM45BGCCROP.${date_var}
cd /E3SM/cime/scripts
./create_newcase --case ${CASE_NAME} --res 1x1_smallvilleIA --compset ICLM45BGCCROP --mach docker --compiler gnu
cd ${CASE_NAME}
./xmlchange --id RUN_STARTDATE --val '1980-01-01'
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id STOP_N --val 1
#./xmlchange DATM_CLMNCEP_YR_END=1991
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run 
./xmlchange EXEROOT=${PWD}/bld
./xmlchange NTASKS=1
#./xmlchange NTASKS_LND=4,ROOTPE_LND=0 
./xmlchange -a CLM_CONFIG_OPTS='-nofire'
./xmlchange DIN_LOC_ROOT_CLMFORC=/inputdata/atm/datm7
./xmlchange DIN_LOC_ROOT=/inputdata/
cd ${CASE_NAME}

# setup case
echo "*** Running case.setup ***"
echo " "
./case.setup

# define output variables and output frequency
cat >> user_nl_clm <<EOF
hist_empty_htapes = .true.
hist_fincl1       = 'NEP','GPP','TOTVEGC','TOTECOSYSC','NPP','TLAI','QVEGT',\
'EFLX_LH_TOT','EFLX_SOIL_GRND','Qle','Qh','HR','AR','Tair','TBOT','Rnet',\
'FSDS','FSR'
hist_mfilt             = 8760
hist_nhtfrq            = -1
EOF

# build case
echo "*** Build case ***"
echo " "
./case.build

echo "*** Finished building new case in CASE: ${CASE_NAME} ***"
echo " "
echo " "
echo " "

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
# eof