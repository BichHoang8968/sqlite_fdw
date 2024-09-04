#!/bin/bash

# Save the list of existing environment variables before sourcing the env_rpmbuild.conf file.
before_vars=$(compgen -v)

source rpm/env_rpmbuild.conf

# Save the list of environment variables after sourcing the env_rpmbuild.conf file
after_vars=$(compgen -v)

# Find new variables created from configuration file
new_vars=$(comm -13 <(echo "$before_vars" | sort) <(echo "$after_vars" | sort))

# Export variables so that scripts or child processes can access them
for var in $new_vars; do
    export "$var"
done

set -eE

# validate parameters
chmod a+x rpm/validate_parameters.sh
./rpm/validate_parameters.sh SQLITE_VERSION SQLITE_YEAR IMAGE_TAG DOCKERFILE ARTIFACT_DIR_WITH_POSTGRES proxy no_proxy PACKAGE_RELEASE_VERSION POSTGRESQL_VERSION SQLITE_FDW_RELEASE_VERSION

# get sqlite download version
SQLITE_DOWNLOAD_VERSION=$(./rpm/convert_sqlite_download_version.sh $SQLITE_VERSION)

# clone sqlite
if [[ ! -f "rpm/deps/sqlite-autoconf-${SQLITE_DOWNLOAD_VERSION}.tar.gz" ]]; then
	cd rpm/deps
	chmod -R 777 ./
	wget https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_DOWNLOAD_VERSION}.tar.gz
	cd ../../
fi

# get base PostgreSQL version
POSTGRESQL_BASE_VERSION=$(echo "$POSTGRESQL_VERSION" | cut -d '.' -f 1)

docker build -t $IMAGE_TAG \
                --build-arg proxy=${proxy} \
                --build-arg no_proxy=${no_proxy} \
                --build-arg PACKAGE_RELEASE_VERSION=${PACKAGE_RELEASE_VERSION} \
                --build-arg POSTGRESQL_BASE_VERSION=${POSTGRESQL_BASE_VERSION} \
                --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
                --build-arg SQLITE_FDW_RELEASE_VERSION=${SQLITE_FDW_RELEASE_VERSION} \
                --build-arg SQLITE_VERSION=${SQLITE_VERSION} \
                --build-arg SQLITE_YEAR=${SQLITE_YEAR} \
                --build-arg SQLITE_DOWNLOAD_VERSION=${SQLITE_DOWNLOAD_VERSION} \
                -f rpm/$DOCKERFILE .

# copy binary to outside
mkdir -p $ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION
docker run --rm -v $(pwd)/$ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "sudo chmod 777 /tmp && cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION/*-debuginfo-*.rpm

# Clean
docker rmi $IMAGE_TAG
