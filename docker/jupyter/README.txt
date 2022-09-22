# Source of notebook builds: https://hub.docker.com/r/jupyter/scipy-notebook

Building dual-platform jupyter-lab containers for analyzing ELM output

First build the main jupyter-lab container, e.g. Jupyter-Lab 3.3.2
docker buildx build --push -t fasstsimulation/fasst_simulation_tools:fasst_jupyterlab_3.3.2 --no-cache  \
--platform linux/amd64,linux/arm64 -f /Users/sserbin/Data/GitHub/fasst_simulation_tools/docker/jupyter/Dockerfile_lab_3.3.2 .

Second build the elmlab container which includes all of the example notebooks
docker buildx build --push -t fasstsimulation/fasst_simulation_tools:elmlab_3.3.2 --no-cache  \
--platform linux/amd64,linux/arm64 -f docker/jupyter/Dockerfile_elmlab_3.3.2 .