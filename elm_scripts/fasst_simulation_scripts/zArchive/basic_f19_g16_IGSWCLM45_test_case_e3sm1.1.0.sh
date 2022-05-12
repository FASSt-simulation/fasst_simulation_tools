#!/bin/bash
# gridded case build test
export date_var=$(date +%s)
export CASE_NAME=/output/f19_g16.IGSWCLM45.${date_var}
cd /E3SM/cime/scripts
./create_newcase --case ${CASE_NAME} --res f19_g16 --compset IGSWCLM45 --mach docker --compiler gnu
cd ${CASE_NAME}
./xmlchange DATM_CLMNCEP_YR_END=1995
./xmlchange PIO_TYPENAME=netcdf
./xmlchange RUNDIR=${PWD}/run 
./xmlchange EXEROOT=${PWD}/bld
./xmlchange NTASKS=1
./xmlchange -a CLM_CONFIG_OPTS='-nofire'
./xmlchange NTASKS_LND=4,ROOTPE_LND=0 
./xmlchange DIN_LOC_ROOT_CLMFORC=/inputdata/atm/datm7
./xmlchange DIN_LOC_ROOT=/inputdata/
cd ${CASE_NAME}
./case.setup
./case.build