# ----------------------------------------------------------------------
# JupyterLab Notebook for analyzing E3SM-ELM land model output
# ----------------------------------------------------------------------

#FROM jupyter/scipy-notebook:latest
#FROM jupyter/datascience-notebook:latest
#https://jupyter-docker-stacks.readthedocs.io/en/latest/
#https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
#https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-scipy-notebook
# MORE INFO: https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html
# https://developers.refinitiv.com/en/article-catalog/article/how-to-set-up-and-run-data-science-development-environment-with-
#https://towardsdatascience.com/how-to-run-jupyter-notebook-on-docker-7c9748ed209f
FROM jupyter/scipy-notebook:lab-3.3.2
LABEL maintainer.name="Shawn P. Serbin" \
      maintainer.email="sserbin@bnl.gov" \
      author.name="Shawn P. Serbin" \
      author.email="sserbin@bnl.gov" \
      description="Jupyter-SciPy Container"

ENV TOOLS_REPOSITORY_RAW_URL=https://raw.githubusercontent.com/FASSt-simulation/fasst_simulation_tools

# install Python packages you often use
RUN set -ex \
   && conda install --quiet --yes \
   # choose the Python packages you need
   'matplotlib' \
   'plotly' \
   'folium' \
   'dask' \
   'pandas' \
   'xarray' \
   'geopandas' \
   && conda install --quiet --yes -c conda-forge 'nc-time-axis' \
   && conda install --quiet --yes -c conda-forge 'netCDF4' \
   && conda install --quiet --yes -c conda-forge 'earthengine-api' \
   && conda clean --all -f -y \
   && mamba install --quiet --yes 'geemap' 'localtileserver' -c conda-forge \
   && mamba clean --all -f -y \
   # install Jupyter Lab extensions you need
   && jupyter labextension install jupyterlab-plotly --no-build \
   && jupyter lab build -y \
   && jupyter lab clean -y \
   && rm -rf "/home/${NB_USER}/.cache/yarn" \
   && rm -rf "/home/${NB_USER}/.node-gyp" \
   && fix-permissions "${CONDA_DIR}" \
   && fix-permissions "/home/${NB_USER}"

# Make local directories to map in ELM output
#RUN mkdir "/home/${NB_USER}/work" && \
#    fix-permissions "/home/${NB_USER}"
RUN mkdir "/home/${NB_USER}/scripts" \
   && mkdir "/home/${NB_USER}/inputdata" \
   && mkdir "/home/${NB_USER}/output" \
   && fix-permissions "/home/${NB_USER}/scripts" \
   && fix-permissions "/home/${NB_USER}/inputdata" \
   && fix-permissions "/home/${NB_USER}/output" \
   && fix-permissions "/home/${NB_USER}"

#RUN mkdir "/scripts" \
#   && mkdir "/inputdata" \
#   &&  mkdir "/output" \
#   && fix-permissions "/scripts" \
#   && fix-permissions "/inputdata" \
#   && fix-permissions "/output"

# Copy in example plotting scripts for use with model output
#https://raw.githubusercontent.com/FASSt-simulation/fasst_simulation_tools/main/elm_scripts/plotting/plot_KG64_ELM_output.py
RUN cd "/home/${NB_USER}/scripts" \
   && wget $TOOLS_REPOSITORY_RAW_URL/main/elm_scripts/plotting/plot_KG64_ELM_output.py \
   && chmod 775 plot_KG64_ELM_output.py

# add Ben Sulman's matplotlib plotting ascetics defaults
RUN cd "/home/${NB_USER}" \
   && mkdir -p "/home/${NB_USER}/.config/matplotlib" \
   && cd "/home/${NB_USER}/.config/matplotlib" \
   && wget $TOOLS_REPOSITORY_RAW_URL/main/elm_scripts/plotting/matplotlibrc \
   && cd "/home/${NB_USER}" \
   && fix-permissions "/home/${NB_USER}"

# Setup default user, when enter docker container
#USER ${UID}:${GID}
#WORKDIR /home/${USER}
# or change this to the scrpts or some other folder to house the default
# scripts?
USER ${NB_UID}
#WORKDIR /home/${NB_UID}
WORKDIR "${HOME}"
#WORKDIR "/scripts"
#WORKDIR "${HOME}/scripts"

# EOF