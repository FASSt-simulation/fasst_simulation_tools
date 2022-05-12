#!/bin/bash

#===============================================================================
# E3SM create_newcase template
#===============================================================================

#------------------------------------
# RUN SPECIFIC SETUP - USER TO MODIFY
#------------------------------------

# Set debugging option on or off
export DEBUGGING=FALSE

# Set the desired compset - use query_config and/or query_testlist for compset names
export COMPSET=IELMFATES

# Set the resolution
export RESOLUTION=1x1_brazil

#------------------------------------------------------
# USER AND MACHINE SPECIFIC SETUP - CHANGE AS NECESSARY
#------------------------------------------------------
export CIME_MODEL=e3sm      # This is actually defined in .cime
export PROJECT=fakeproject
export CATEGORY=fates
export MACH=docker
export COMPILER=gnu
export CASEDIR=/output

#---------------------------------------------------------
# SETUP DIRECTORY - USER SHOULD NOT NEED TO CHANGE THESE
#---------------------------------------------------------
# Move to the script directory - handles call from docker cli
cd /scripts

# Setup githash to append to test directory name
export ELMHASH=`cd ../../;git log -n 1 --format=%h`
export FATESHASH=`(cd ../../components/clm/src/external_models/fates;git log -n 1 --format=%h)`
export GITHASH="E"${ELMHASH}"-F"${FATESHASH}

# Setup build, run and output directory
export CASENAME=${CASEDIR}/${MACH}.${RESOLUTION}.${COMPSET}.${CIME_MODEL}.${CATEGORY}.${GITHASH}

#----------------
# CREATE THE CASE
#----------------
./create_newcase --case=${CASENAME} --project=${PROJECT} --res=${RESOLUTION} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} 

# Change to the created case directory
cd ${CASENAME}

#--------------------------------------------------------
# UPDATE CASE CONFIGURATION - USER TO UPDATE AS NECESSARY
#--------------------------------------------------------

# The following is from the fates tutorial 
./xmlchange --id STOP_N --val 1
./xmlchange --id RUN_STARTDATE --val '2001-01-01'
./xmlchange --id STOP_OPTION --val nyears
./xmlchange --id DATM_CLMNCEP_YR_START --val 1996
./xmlchange --id DATM_CLMNCEP_YR_END --val 2001
./xmlchange --id CLM_FORCE_COLDSTART --val on

#-------------------------------------------------------------------
# UPDATE OUTPUT STRUCTURE AND OTHERS - USER SHOULDN'T NEED TO UPDATE
#-------------------------------------------------------------------
# Change the debugging setup
./xmlchange DEBUG=${DEBUGGING}

# Change the output root where CASENAME/bld and CASENAME/run directories will be placed
./xmlchange CIME_OUTPUT_ROOT=${CASEDIR}

# Change the output dir for short term archives (i.e. the run logs)
./xmlchange DOUT_S_ROOT=${CASENAME}/run

# SPECIFY PE LAYOUT FOR SINGLE SITE RUN (USERS WILL PROB NOT CHANGE THESE)

#-------------------------
# SETUP AND BUILD THE CASE
#-------------------------
./case.setup
./case.build

# MANUALLY SUBMIT CASE
echo "To submit the case change directory to ${CASENAME} and run ./case.submit"