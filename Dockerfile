# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Brent Kendrick"

USER root

# ffmpeg for matplotlib anim & dvipng+cm-super for latex labels (from scipy build)
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg dvipng cm-super && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# install everything else as jovyan
USER $NB_UID
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

# USER $NB_UID

# Install Python 3 packages
RUN conda install --quiet --yes \
    'beautifulsoup4=4.9.*' \
    # 'bqplot=0.12.18'\
    #'conda-forge::blas=*=openblas' \
    #'bokeh=2.2.*' \
    'bottleneck=1.3.*' \
    #'cloudpickle=1.6.*' \
    'cython=0.29.*' \
    'dask=2.30.*' \
    #'dill=0.3.*' \
    #'h5py=3.1.*' \
    'ipywidgets=7.5.*' \
    'ipympl=0.5.*'\
    # 'ipysheet=0.4.*'\
    'ipyvolume=0.5.*'\
    'ipyvuetify=1.5.*'\
    'jupytext=1.6.0' \
    'matplotlib-base=3.3.*' \
    'numpy=1.19.*' \
    #'numba=0.51.*' \
    #'numexpr=2.7.*' \
    'pandas=1.1.*' \
    # 'patsy=0.5.*' \
    'peakutils=1.3.3' \
    'plotly=4.13.0' \
    # 'protobuf=3.13.*' \
    # 'pytables=3.6.*' \
    # 'scikit-image=0.17.*' \
    # 'scikit-learn=0.23.*' \
    'scipy=1.5.*' \
    'seaborn=0.11.*' \
    # 'sqlalchemy=1.3.*' \
    # 'statsmodels=0.12.*' \
    # 'sympy=1.7.*' \
    # 'vincent=0.4.*' \
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
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    # jupyter labextension install @bokeh/jupyter_bokeh@^2.0.0 --no-build && \
    jupyter labextension install jupyterlab-jupytext --no-build && \
    jupyter labextension install jupyterlab-plotly@4.13.0 --no-build && \
    jupyter labextension install @jupyter-voila/jupyterlab-preview --no-build && \
    # jupyter labextension install bqplot --no-build && \
    jupyter labextension install jupyter-vuetify --no-build && \
    jupyter labextension install ipyvolume --no-build && \
    jupyter labextension install jupyter-matplotlib --no-build && \
    # jupyter labextension install ipysheet --no-build && \
    jupyter lab build --dev-build=False --minimize=False -y && \
    jupyter lab clean -y && \
    npm cache clean --force && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    rm -rf "/home/${NB_USER}/.node-gyp" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# RUN jupyter labextension install @jupyter-voila/jupyterlab-preview --no-build && \
#     jupyter lab build --dev-build=False --minimize=False -y && \
#     jupyter lab clean -y && \
#     npm cache clean --force && \
#     rm -rf "/home/${NB_USER}/.cache/yarn" && \
#     rm -rf "/home/${NB_USER}/.node-gyp" && \
#     fix-permissions "${CONDA_DIR}" && \
#     fix-permissions "/home/${NB_USER}"

# RUN mkdir /home/jovyan/notebooks
# COPY environment.yml /home/jovyan
# RUN conda env update -n base --file /home/jovyan/environment.yml
# COPY ./notebooks /home/jovyan/notebooks

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

WORKDIR $HOME