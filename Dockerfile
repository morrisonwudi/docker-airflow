# VERSION 1.8.0
# AUTHOR: Gaetan Semet
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t stibbons31/docker-airflow-mesos .
# SOURCE: https://github.com/Stibbons/docker-airflow-mesos
# REFERENCES:
#     - https://github.com/puckel/docker-airflow
#     - https://github.com/ImDarrenG/mesos-framework-dev/blob/master/Dockerfile


FROM ubuntu:16.04
MAINTAINER Gaetan Semet <gaetan@xeberon.net>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.8.0
ARG AIRFLOW_HOME=/usr/local/airflow

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV MESOS_VERSION 1.0.1


# Install Dependencies
RUN apt-get update -q --fix-missing
RUN apt-get -qy install software-properties-common # (for add-apt-repository)
RUN add-apt-repository -y ppa:george-edison55/cmake-3.x
RUN apt-get update -q
RUN apt-get -qy install \
  autoconf                                \
  automake                                \
  build-essential                         \
  ca-certificates                         \
  cmake=3.5.2-2ubuntu1~ubuntu16.04.1~ppa1 \
  g++                                     \
  gdb                                     \
  git-core                                \
  heimdal-clients                         \
  libapr1-dev                             \
  libboost-dev                            \
  libcurl4-nss-dev                        \
  libgoogle-glog-dev                      \
  libprotobuf-dev                         \
  libpython-dev                           \
  libsasl2-dev                            \
  libsasl2-modules-gssapi-heimdal         \
  libsvn-dev                              \
  libtool                                 \
  make                                    \
  protobuf-compiler                       \
  python                                  \
  python-dev                              \
  python-pip                              \
  python-protobuf                         \
  python-setuptools                       \
  python-virtualenv                       \
  python2.7                               \
  unzip                                   \
  wget                                    \
  zlib1g-dev                              \
  --no-install-recommends


# Install the picojson headers
RUN wget https://raw.githubusercontent.com/kazuho/picojson/v1.3.0/picojson.h -O /usr/local/include/picojson.h

# Prepare to build Mesos
RUN mkdir -p /mesos
RUN mkdir -p /tmp
RUN mkdir -p /usr/share/java/
RUN wget http://search.maven.org/remotecontent?filepath=com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar -O protobuf.jar
RUN mv protobuf.jar /usr/share/java/

WORKDIR /mesos

# Clone Mesos (master branch)

RUN git clone -v https://github.com/apache/mesos.git /mesos
RUN git checkout ${MESOS_VERSION}
RUN git log -n 1

# Bootstrap
RUN cd /mesos/ && ./bootstrap

# Configure
RUN mkdir /mesos/build && cd /mesos/build && ../configure --disable-java --disable-optimize --with-glog=/usr/local --with-protobuf=/usr --with-boost=/usr/local

# Build Mesos
RUN cd /mesos/build && make -j4 install

RUN find /mesos -name "*.egg"

# Install python eggs
RUN cd /mesos/build/src/python/dist/ && easy_install mesos.interface-*.egg
RUN cd /mesos/build/src/python/dist/ && easy_install mesos.executor-*.egg
RUN cd /mesos/build/src/python/dist/ && easy_install mesos.scheduler-*.egg
RUN cd /mesos/build/src/python/dist/ && easy_install mesos.native-*.egg
RUN cd /mesos/build/src/python/dist/ && easy_install mesos.cli-*.egg
RUN cd /mesos/build/src/python/dist/ && easy_install mesos-*.egg


RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yq \
    && apt-get install -yq --no-install-recommends \
        $buildDeps \
        python-pip \
        python-requests \
        apt-utils \
        curl \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && python -m pip install -U pip \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install airflow[crypto,celery,postgres,hive,hdfs,jdbc]==$AIRFLOW_VERSION \
    && pip install celery[redis]==3.1.17 \
    && apt-get remove --purge -yq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

RUN set -ex \
    && pip install mesos.cli \
    && pip install airflow[github_enterprise,redis,docker]==$AIRFLOW_VERSION

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

ENV PYTHONPATH ${PYTHONPATH}:/usr/lib/python2.7/site-packages/

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow

WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
