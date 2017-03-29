# docker-airflow-mesos
[![CircleCI branch](https://img.shields.io/circleci/project/Stibbons/docker-airflow-mesos/master.svg?maxAge=2592000)](https://circleci.com/gh/Stibbons/docker-airflow-mesos/tree/master)
[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/stibbons31/docker-airflow-mesos/)
[![Docker Pulls](https://img.shields.io/docker/pulls/stibbons31/docker-airflow-mesos.svg?maxAge=2592000)]()
[![Docker Stars](https://img.shields.io/docker/stars/stibbons31/docker-airflow-mesos.svg?maxAge=2592000)]()

This repository contains **Dockerfile** of [airflow](https://github.com/apache/incubator-airflow) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/puckel/docker-airflow/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

## Informations

* Based on Ubunutu 16.04 image and uses the official [Postgres](https://hub.docker.com/_/postgres/) as backend and [Redis](https://hub.docker.com/_/redis/) as queue
* Install [Docker](https://www.docker.com/)
* Following the Airflow release from [Python Package Index](https://pypi.python.org/pypi/airflow)

## Installation

Pull the image from the Docker repository.

        docker pull stibbons31/docker-airflow-mesos

## Build

For example, if you need to install [Extra Packages](https://pythonhosted.org/airflow/installation.html#extra-package), edit the Dockerfile and then build it.

        docker build --rm -t puckel/docker-airflow .

## Usage

By default, docker-airflow-mesos runs Airflow with **MesosExecutor** :

        docker run -d -p 8080:8080 Stibbons/docker-airflow

The following environment variable should be provided:

    POSTGRES_USER: xxx
    POSTGRES_PASSWORD: xxx
    POSTGRES_HOST: xxx
    POSTGRES_PORT: xxx
    POSTGRES_DB: xxx
    REDIS_HOST: xxx
    REDIS_PORT: xxx

NB : If you don't want to have DAGs example loaded (default=True), you've to set the following environment variable :

`LOAD_EX=n`

        docker run -d -p 8080:8080 -e LOAD_EX=n puckel/docker-airflow

If you want to use Ad hoc query, make sure you've configured connections:
Go to Admin -> Connections and Edit "postgres_default" set this values (equivalent to values in airflow.cfg/docker-compose*.yml) :
- Host : postgres
- Schema : airflow
- Login : airflow
- Password : airflow

For encrypted connection passwords (in Local or Celery Executor), you must have the same fernet_key. By default docker-airflow generates the fernet_key at startup, you have to set an environment variable in the docker-compose (ie: docker-compose-LocalExecutor.yml) file to set the same key accross containers. To generate a fernet_key :

        python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print FERNET_KEY"

Check [Airflow Documentation](https://pythonhosted.org/airflow/)


## Install custom python package

- Create a file "requirements.txt" with the desired python modules
- Mount this file as a volume `-v $(pwd)/requirements.txt:/requirements.txt`
- The entrypoint.sh script execute the pip install command (with --user option)

## UI Links

- Airflow: [localhost:8080](http://localhost:8080/)
- Flower: [localhost:5555](http://localhost:5555/)

When using OSX with boot2docker, use: open http://$(boot2docker ip):8080

## Scale the number of workers

Easy scaling using docker-compose:

        docker-compose scale worker=5

This can be used to scale to a multi node setup using docker swarm.

# Wanna help?

Fork, improve and PR. ;-)
