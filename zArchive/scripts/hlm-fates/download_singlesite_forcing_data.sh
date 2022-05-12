#!/bin/bash

# =======================================================================================
#
# INSTALL Python OSF API Client
# pip3 install osfclient
#
#
# Usage guide
# https://osfclient.readthedocs.io/en/latest/cli-usage.html
# =======================================================================================

# =======================================================================================
# USER OPTIONS
# path to "single_site" directory within main CESM data directory located on the host
# machine
cesm_data_dir=~/Data/cesm_input_datasets/single_site
mkdir -p ${cesm_data_dir}
# =======================================================================================

# =======================================================================================
echo "*** Downloading and extracting forcing data from OSF ***"

### get remote forcing data from OSF
# osf fetch --help
osf -p kv93n fetch -U single_site_forcing/GSWP3_PA-SLZ_met_forcing_partial.tar.gz \
${cesm_data_dir}/GSWP3_PA-SLZ_met_forcing_partial.tar.gz

### extract forcing data
cd ${cesm_data_dir}
tar -zxf GSWP3_PA-SLZ_met_forcing_partial.tar.gz
# =======================================================================================

# =======================================================================================
# done
echo "*** DONE ***"
# =======================================================================================