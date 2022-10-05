#!/bin/bash

#-----------------------------------
# Run test suite to ensure all cases are
# running as expected
#-----------------------------------
# options to reset containers if chosen
for i in "$@"
do
case $i in
    -sn=*|--site_name=*)
    site_name="${i#*=}"
    shift # past argument=value
    ;;
    -r=*|--reset_containers=*)
    reset_containers="${i#*=}"
    shift
    ;;    
    -adsy=*|--ad_spinup_years=*)
    ad_spinup_years="${i#*=}"
    shift # past argument=value
    ;;
    -fsy=*|--final_spinup_years=*)
    final_spinup_years="${i#*=}"
    shift # past argument=value
    ;;
    -trsy=*|--transient_years=*)
    transient_years="${i#*=}"
    shift # past argument=value
    ;;
    -rcn=*|--run_container_name=*)
    run_container_name="${i#*=}"
    shift
    ;;
    -jcn=*|--jupyterlab_container_name=*)
    jupyterlab_container_name="${i#*=}"
    shift
    ;;
    *) # unknown option
    ;;
esac
done

# set defaults:
site_name="${site_name:-kougarok}"
reset_containers="${reset_containers:-no}"
ad_spinup_years="${ad_spinup_years:-20}"
final_spinup_years="${final_spinup_years:-30}"
transient_years="${transient_years:-10}"
run_container_name="${run_container_name:-fasstsimulation/elm-builds:elm_v2-for-ngee_multiarch}"
jupyterlab_container_name="${jupyterlab_container_name:-fasstsimulation/fasst_simulation_tools:elmlab_3.3.2}"

echo $run_container_name
echo $jupyterlab_container_name

# remove existing containers if reset_containers=yes
if [ ${reset_containers} = yes ]; then
  echo "Removing existing container versions:"
  docker rmi ${run_container_name}
  docker rmi ${jupyterlab_container_name}
fi
#===========================================

# setup volumes specific for testing suite
echo "Creating test docker volumes..."
docker volume create test_elmdata
docker volume create test_elmoutput

# pull latest version of docker containers
echo "Getting latest version of containers..."
docker pull ${run_container_name}
docker pull ${jupyterlab_container_name}

# run data retrieval script
echo "Retrieve forcing data..."
docker run --rm -t -i --hostname=docker --user modeluser -v \
test_elmdata:/inputdata ${run_container_name} \
/scripts/download_elm_singlesite_forcing_data.sh

# set common args for all runs:
common_args="${run_container_name} /scripts/OLMT_docker_example.sh --site_name=${site_name}"
common_args="${common_args} --ad_spinup_years=${ad_spinup_years} --final_spinup_years=${final_spinup_years} --transient_years=${transient_years}"

# run base case
docker run --rm -t -i --hostname=docker --user modeluser -v test_elmdata:/inputdata \
-v test_elmoutput:/output ${common_args}

# test scaling options
docker run --rm -t -i --hostname=docker --user modeluser -v test_elmdata:/inputdata \
-v test_elmoutput:/output ${common_args} \
--scale_ndep=2.0 --startdate_scale_ndep=18500101 \
--scale_pdep=2.0 --startdate_scale_pdep=18500101 \
--scale_rain=2.0 --startdate_scale_rain=18500101 \
--scale_snow=2.0 --startdate_scale_snow=18500101 \
--add_temperature=5.0 --startdate_add_temperature=18500101 \
--add_co2=200.0 --startdate_add_co2=18500101 \
--case_prefix=sclmore

docker run --rm -t -i --hostname=docker --user modeluser -v test_elmdata:/inputdata \
-v test_elmoutput:/output ${common_args} \
--scale_ndep=0.5 --startdate_scale_ndep=18500101 \
--scale_pdep=0.5 --startdate_scale_pdep=18500101 \
--scale_rain=0.5 --startdate_scale_rain=18500101 \
--scale_snow=0.5 --startdate_scale_snow=18500101 \
--add_temperature=-5.0 --startdate_add_temperature=18500101 \
--add_co2=-200.0 --startdate_add_co2=18500101 \
--case_prefix=sclless

############
# test out cases we might actually want to run:
###########
docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} --case_prefix="base"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_snow=1.4 --startdate_scale_snow=18550101 --scale_rain=2.0 --startdate_scale_rain=18550101 --case_prefix="future_P"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--add_temperature=8.5 --startdate_add_temperature=18550101 --case_prefix="future_T"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_snow=1.4 --startdate_scale_snow=18550101 --scale_rain=2.0 --startdate_scale_rain=18550101 \
--add_temperature=8.5 --startdate_add_temperature=18550101 --case_prefix="future_TP"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_ndep=2.0 --startdate_scale_ndep=18550101 --case_prefix="double_N"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_pdep=2.0 --startdate_scale_pdep=18550101 --case_prefix="double_P"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_pdep=2.0 --startdate_scale_pdep=18550101 --scale_ndep=2.0 --startdate_scale_ndep=18550101 \
--case_prefix="double_NP"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_pdep=0.5 --startdate_scale_pdep=18550101 --case_prefix="halfScale_P"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_ndep=0.5 --startdate_scale_ndep=18550101 --case_prefix="halfScale_N"

docker run --rm -t -i --hostname=docker --user modeluser -v elmdata:/inputdata -v elmoutput:/output ${common_args} \
--scale_ndep=0.5 --startdate_scale_ndep=18550101 --scale_pdep=0.5 --stardate_scale_pdep=18550101 \
--case_prefix="halfScale_NP" 

# print some info to screen.
echo " "
echo "**********************************"
echo "All test runs completed - check to"
echo "ensure ELM_output for above cases "
echo "is present when viz container is"
echo "tested below"
echo "**********************************"
echo " "

# test that viz container opens
docker run -p 8888:8888 -v elmdata:/home/jovyan/inputdata -v elmoutput:/home/jovyan/output \
${jupyterlab_container_name}

