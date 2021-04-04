#name of container: docker-ijulia-notebook
#versison of container: 0.7
FROM quantumobject/docker-baseimage:20.04
MAINTAINER Angel Rodriguez  "angel@quantumobject.com"

# Update the container
# Installation of nesesary package/software for this containers...
RUN curl -sL https://deb.nodesource.com/setup_15.x |  bash  && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends apt-utils \
                    git \
                    bzip2 \
                    unzip \
                    libcairo2-dev libpango1.0-0 libpango1.0-dev zlib1g-dev tk-dev tcl-dev \
                    glib2.0 \
                    file \
                    ca-certificates \
                    libsm6 \
                    pandoc \
                    texlive \
                    libxrender1 \
                    gfortran \
                    gcc \
                    fonts-dejavu \
                    libglib2.0-dev \
                    librsvg2-dev \
                    libpixman-1-dev \
                    hdf5-tools \
                    glpk-utils \
                    libnlopt0 \
                    imagemagick \
                    inkscape \
                    gettext \
                    libreadline-dev \
                    libncurses-dev \
                    libpcre3-dev \
                    libgnutls28-dev \
                    tmux \
                    pkg-config \
                    pdf2svg \
                    libc6 \
                    libc6-dev \
                    software-properties-common \
                    coinor-* libtool \
                    libffi-dev \
                    libssl-dev \
                    libzmq3-dev \
                    libsundials-cvodes3 \
                    libsundials-ida3 \
                    libnlopt-dev \
                    openmpi-bin \
                    libopenmpi-dev \
                    libblosc-dev \
                    ffmpeg  tzdata\
                    libgmp-dev libglpk-dev \
                    libmumps-dev nodejs

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.6.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "463b71dc70ca7094c0e0fd6d55d130051a7901e8dec5eb44d6002c57d1bd8585 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV CONDA_JL_HOME $CONDA_DIR/conda_jl
ENV SHELL /bin/bash

# Show Julia where conda libraries are \
RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR 

##startup scripts  
#Pre-config scrip that maybe need to be run one time only when the container run the first time .. using a flag to don't 
#run it again ... use for conf for service ... when run the first time ...
RUN mkdir -p /etc/my_init.d
COPY startup.sh /etc/my_init.d/startup.sh
RUN chmod +x /etc/my_init.d/startup.sh

##Adding Deamons to containers
RUN mkdir /etc/service/ijulia
COPY ijulia.sh /etc/service/ijulia/run
RUN chmod +x /etc/service/ijulia/run

#pre-config scritp for different service that need to be run when container image is create 
#maybe include additional software that need to be installed ... with some service running ... like example mysqld
COPY pre-conf.sh /sbin/pre-conf
RUN chmod +x /sbin/pre-conf  ; sync \
    && /bin/bash -c /sbin/pre-conf \
    && rm /sbin/pre-conf

#add files and script that need to be use for this container
#include conf file relate to service/daemon 
#additionsl tools to be use internally 
COPY after_install.sh /sbin/after_install
RUN chmod +x /sbin/after_install

# to allow access from outside of the container  to the container service
# at that ports need to allow access from firewall if need to access it outside of the server. 
EXPOSE 8998

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
