# VERSION 1.8.0
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t Stibbons/docker-airflow .
# SOURCE: https://github.com/Stibbons/docker-airflow

FROM debian:jessie
MAINTAINER Stibbons

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
# Released version:
#   ARG AIRFLOW_VERSION=1.8.0
#   ARG AIRFLOW_REPO=https://github.com/apache/incubator-airflow.git
#   ARG AIRFLOW_COMMIT=
# HEAD:
ARG AIRFLOW_VERSION=1.9.0+fs1
ARG AIRFLOW_HOME=/usr/local/airflow
ARG AIRFLOW_REPO=https://github.com/Stibbons/incubator-airflow
ARG AIRFLOW_COMMIT=b55f41f2c22e210d130a0b42586f0385bd5515a7
ARG AIRFLOW_OPTS=crypto,celery,postgres,hive,hdfs,jdbc,redis

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

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
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
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
    && ( \
        ( [ ! -z $AIRFLOW_COMMIT ] \
            && pip install git+$AIRFLOW_REPO@$AIRFLOW_COMMIT#egg=airflow[$AIRFLOW_OPTS]==$AIRFLOW_VERSION \
            && pip install html5lib==1.0b8 \
        ) || ( \
               pip install airflow[$AIRFLOW_OPTS]==$AIRFLOW_VERSION \
            && pip install celery[redis]==3.1.17 \
        ) \
       ) \
    && apt-get remove --purge -yqq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

RUN set -ex \
    && pip install bleach==2.0 html5lib==1.0b10 six==1.10.0 redis

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
