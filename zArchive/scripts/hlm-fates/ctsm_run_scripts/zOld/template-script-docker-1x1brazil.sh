#!/bin/bash

#===============================================================================
# CTSM create_newcase template for docker container
#===============================================================================

#----------------------------------------------------------------------------------
# RUN SPECIFIC SETUP - USER TO MODIFY
#----------------------------------------------------------------------------------
# Set a descriptive name for the case to be run
export DESCNAME=my-descriptive-case-name

# Set debugging option on or off
export DEBUGGING=FALSE

# Set the desired compset - use query_config and/or query_testlist for compset names
export COMPSET=I2000Clm50FatesCruGs

# Set the resolution
export RESOLUTION=1x1_brazil

# Match the output and input directories to the docker run -v volume mount option
export CASEDIR=/output          # /output is default
export INPUTDIR=/inputdata      # /inputdata is default

#----------------------------------------------------------------------------------
# DOCKER MACHINE SPECIFIC ARGUMENTS - DO NOT CHANGE
#----------------------------------------------------------------------------------
export CATEGORY=fates          # For descriptive use in the casename
export COMPILER=gnu            # Currently only gcc compilers supported
export MODEL_SOURCE=/CTSM      # Location of ctsm hlm
export MACH=${HOSTNAME}        # This is set via --hostname=docker option

#----------------------------------------------------------------------------------
# SETUP DIRECTORY - USER SHOULD NOT NEED TO CHANGE THESE
#----------------------------------------------------------------------------------
# Switch to host land model
echo "Running with CTSM location: "${MODEL_SOURCE}
cd ${MODEL_SOURCE}/cime/scripts

# Setup githash to append to test directory name for reproducability
export CLMHASH=`cd ../../;git log -n 1 --format=%h`
export FATESHASH=`(cd ../../src/fates;git log -n 1 --format=%h)`
export GITHASH="C"${CLMHASH}"-F"${FATESHASH}

# Setup build, run and output directory name
export CASENAME=${CASEDIR}/${DESCNAME}.${CATEGORY}.${MACH}.${GITHASH}

#----------------------------------------------------------------------------------
# CREATE THE CASE
#----------------------------------------------------------------------------------
echo "Calling create_newcase"
./create_newcase --case=${CASENAME} --res=${RESOLUTION} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --run-unsupported

# Change to the created case directory
echo "Changing to case directory: " ${CASENAME}
cd ${CASENAME}

#----------------------------------------------------------------------------------
# UPDATE CASE CONFIGURATION - user to update or add as necessary
#----------------------------------------------------------------------------------
echo "Calling xmlchange"

# Change the run time settings
./xmlchange STOP_N=2
./xmlchange STOP_OPTION=nyears

# Change the debugging setup to match above argument
./xmlchange DEBUG=${DEBUGGING}

# Override the .cime configuration default to match the above argument for dir locations
./xmlchange CIME_OUTPUT_ROOT=${CASEDIR}
./xmlchange DIN_LOC_ROOT=${INPUTDIR}
./xmlchange DIN_LOC_ROOT_CLMFORC=${INPUTDIR}/atm/datm7

# Change the output dir for short term archives (i.e. the run logs) - do not change
./xmlchange DOUT_S_ROOT=${CASENAME}/run

#----------------------------------------------------------------------------------
# SETUP AND BUILD THE CASE
#----------------------------------------------------------------------------------
echo "Setting up case"
./case.setup
echo "Building case"
./case.build

# MANUALLY SUBMIT CASE
echo "To submit the case change directory to ${CASENAME} and run ./case.submit"
