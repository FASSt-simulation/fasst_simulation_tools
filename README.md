# FASSt-Simulation Run Scripts and Analysis Tools
Scripts and tools for running the FASSt-simulation model containers


### FASSt-Simulation
[placeholder]


### NGEE-Arctic
Steps to get started:

1) Download cpl_bypass met driver data

```
export container=fasstsimulation/elm-builds:release-v1.2.0_ngeearctic-latest
export host_location=/Users/sserbin/Data/testing
export repo=/Users/sserbin/Data/GitHub/fasst_simulation_tools
docker run -t -i --hostname=docker --user $(id -u):$(id -g) -v $host_location:/inputdata \
-v $repo:/scripts $container scripts/met_scripts/ngeearctic/download_elm_singlesite_forcing_data.sh
```
The inputs needed:
which container to run; default fasstsimulation/elm-builds:release-v1.2.0_ngeearctic-latest

The host machine location for the met data, e.g. above /Users/sserbin/Data/testing

The location of this repo code on the host machine to "map in" the scripts to the container



2) 
