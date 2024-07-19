#!/bin/bash

source docker/env_rpmbuild.conf
set -eE

# clone sqlite
if [[ ! -f "docker/deps/sqlite-autoconf-${SQLITE_VERSION}.tar.gz" ]]; then
	cd docker/deps
	chmod -R 777 ./
	wget https://www.sqlite.org/2023/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
	cd ../../
fi

docker build -t $IMAGE_TAG \
                --build-arg proxy=${proxy} \
                --build-arg no_proxy=${no_proxy} \
                --build-arg DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                --build-arg POSTGRESQL_BASE_VERSION=${POSTGRESQL_BASE_VERSION} \
                --build-arg POSTGRESQL_RELEASE_VERSION=${POSTGRESQL_RELEASE_VERSION} \
                --build-arg SQLITE_FDW_RELEASE_VERSION=${SQLITE_FDW_RELEASE_VERSION} \
                --build-arg SQLITE_VERSION=${SQLITE_VERSION} \
                --build-arg SQLITE_RELEASE_VERSION=${SQLITE_RELEASE_VERSION} \
                -f docker/$DOCKERFILE .

# copy binary to outside
mkdir -p $RPM_ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION
docker run --rm -v $(pwd)/$RPM_ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "sudo chmod 777 /tmp && cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $RPM_ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION/*-debuginfo-*.rpm

# Clean
docker rmi $IMAGE_TAG
