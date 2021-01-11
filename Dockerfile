# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

USER root

# ffmpeg for matplotlib anim & dvipng for latex labels
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg dvipng && \
    rm -rf /var/lib/apt/lists/*

USER $NB_UID


# Install Python 3 packages
RUN conda install --quiet --yes \
    'beautifulsoup4=4.9.*' \
    'conda-forge::blas=*=openblas' \
    'bokeh=2.1.*' \
    'bottleneck=1.3.*' \
    'cloudpickle=1.5.*' \
    'cython=0.29.*' \
    'dask=2.20.*' \
    'dill=0.3.*' \
    'h5py=2.10.*' \
    'hdf5=1.10.*' \
    'ipywidgets=7.5.*' \
    'ipympl=0.5.*'\
    'matplotlib-base=3.2.*' \
    # numba update to 0.49 fails resolving deps.
    'numba=0.48.*' \
    'numexpr=2.7.*' \
    'pandas=1.0.*' \
    'patsy=0.5.*' \
    'plotly=4.13.0' \
    'protobuf=3.12.*' \
    'pytables=3.6.*' \
    'scikit-image=0.17.*' \
    'scikit-learn=0.23.*' \
    'scipy=1.5.*' \
    'seaborn=0.10.*' \
    'sqlalchemy=1.3.*' \
    'statsmodels=0.11.*' \
    'sympy=1.6.*' \
    'vincent=0.4.*' \
    'voila=0.2.*' \
    'voila-vuetify=0.5.*'\
    'widgetsnbextension=3.5.*'\
    'xlrd=1.2.*' \
    && \
    conda clean --all -f -y && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # Also activate ipywidgets extension for JupyterLab
    # Check this URL for most recent compatibilities
    # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build && \
    jupyter labextension install @bokeh/jupyter_bokeh@^2.0.0 --no-build && \
    jupyter labextension install jupyter-matplotlib@^0.7.2 --no-build && \
    jupyter lab build -y && \
    jupyter lab clean -y && \
    npm cache clean --force && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    rm -rf "/home/${NB_USER}/.node-gyp" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"



# Configure git user
RUN git config --global user.email "brentkend@gmail.com" && \
    git config --global user.name "brentkendrick"


# clone the git repo containing necessary files
WORKDIR /home/jovyan/
RUN git clone https://github.com/brentkendrick/jupyter-lab-public.git

# # Create virtual env 
# WORKDIR /home/ubuntu/docker_ubuntu_miniconda2 
# RUN conda env create -f environment.yml
# # Pull the environment name out of the environment.yml
# RUN echo "source activate $(head -1 environment.yml | cut -d' ' -f2)" > ~/.bashrc
# ENV PATH /opt/conda/envs/$(head -1 environment.yml | cut -d' ' -f2)/bin:$PATH

RUN mv /home/jovyan/jupyter-lab-public/jupyter-config-files/jupyter_config.py /home/jovyan/.jupyter
RUN mv /home/jovyan/jupyter-lab-public/jupyter-config-files/jupyter_notebook_config.py /home/jovyan/.jupyter


# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"

RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

EXPOSE 5574

# USER $NB_UID
# Run Jupyter notebook as Docker main process
RUN rm -r /home/jovyan/jupyter-lab-public

# Run git clone every time container starts to pull latest data/notebooks
CMD git clone https://github.com/brentkendrick/jupyter-lab-public.git && \
  jupyter lab --allow-root
USER $NB_UID
WORKDIR $HOME