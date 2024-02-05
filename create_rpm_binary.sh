#!/bin/bash

source env_rpmbuild.conf
set -eE

# clone sqlite
if [[ ! -f "deps/sqlite-autoconf-${SQLITE_VERSION}.tar.gz" ]]; then
	cd deps
	chmod -R 777 ./
	wget https://www.sqlite.org/2023/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
	cd ..
fi

if [[ ${PGSPIDER_RPM_ID} ]]; then
    PGSPIDER_RPM_ID_POSTFIX="-${PGSPIDER_RPM_ID}"
fi

# create rpm on container environment
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then 
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg ACCESS_TOKEN=${ACCESS_TOKEN} \
                 --build-arg DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg PGSPIDER_BASE_POSTGRESQL_VERSION=${PGSPIDER_BASE_POSTGRESQL_VERSION} \
                 --build-arg PGSPIDER_RELEASE_VERSION=${PGSPIDER_RELEASE_VERSION} \
                 --build-arg PGSPIDER_RPM_ID=${PGSPIDER_RPM_ID_POSTFIX} \
                 --build-arg PGSPIDER_PROJECT_ID=$PGSPIDER_PROJECT_ID \
                 --build-arg SQLITE_FDW_RELEASE_VERSION=${SQLITE_FDW_RELEASE_VERSION} \
                 --build-arg SQLITE_VERSION=$SQLITE_VERSION \
                 --build-arg SQLITE_RELEASE_VERSION=$SQLITE_RELEASE_VERSION \
                 -f $DOCKERFILE .
else
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg PGSPIDER_BASE_POSTGRESQL_VERSION=${PGSPIDER_BASE_POSTGRESQL_VERSION} \
                 --build-arg PGSPIDER_RELEASE_VERSION=${PGSPIDER_RELEASE_VERSION} \
                 --build-arg PGSPIDER_RPM_ID=${PGSPIDER_RPM_ID_POSTFIX} \
                 --build-arg PGSPIDER_PROJECT_ID=$PGSPIDER_PROJECT_ID \
                 --build-arg SQLITE_FDW_RELEASE_VERSION=${SQLITE_FDW_RELEASE_VERSION} \
                 --build-arg SQLITE_VERSION=${SQLITE_VERSION} \
                 --build-arg SQLITE_RELEASE_VERSION=${SQLITE_RELEASE_VERSION} \
                 -f $DOCKERFILE .
fi

# copy binary to outside
mkdir -p $RPM_ARTIFACT_DIR
docker run --rm -v $(pwd)/$RPM_ARTIFACT_DIR:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $RPM_ARTIFACT_DIR/*-debuginfo-*.rpm

# Push binary on repo
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then
    curl_command="curl --header \"PRIVATE-TOKEN: ${ACCESS_TOKEN}\" --insecure --upload-file"
    package_uri="https://tccloud2.toshiba.co.jp/swc/gitlab/api/v4/projects/${SQLITE_FDW_PROJECT_ID}/packages/generic/rpm_${RPM_DISTRIBUTION_TYPE}/${PGSPIDER_BASE_POSTGRESQL_VERSION}"

    # sqlite
    eval "$curl_command ${RPM_ARTIFACT_DIR}/sqlite-${SQLITE_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/sqlite-${SQLITE_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # sqlite_fdw
    eval "$curl_command ${RPM_ARTIFACT_DIR}/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # debugsource
    eval "$curl_command ${RPM_ARTIFACT_DIR}/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # llvmjit
    eval "$curl_command ${RPM_ARTIFACT_DIR}/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-llvmjit-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-llvmjit-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
else
    curl_command="curl -L \
                            -X POST \
                            -H \"Accept: application/vnd.github+json\" \
                            -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \
                            -H \"X-GitHub-Api-Version: 2022-11-28\" \
                            -H \"Content-Type: application/octet-stream\" \
                            --insecure"
    assets_uri="https://uploads.github.com/repos/${OWNER_GITHUB}/${SQLITE_FDW_PROJECT_GITHUB}/releases/${SQLITE_FDW_RELEASE_ID}/assets"
    binary_dir="--data-binary \"@${RPM_ARTIFACT_DIR}\""

    # sqlite
    eval "$curl_command $assets_uri?name=sqlite-${SQLITE_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/sqlite-${SQLITE_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # sqlite_fdw
    eval "$curl_command $assets_uri?name=sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # debugsource
    eval "$curl_command $assets_uri?name=sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # llvmjit
    eval "$curl_command $assets_uri?name=sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-llvmjit-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/sqlite_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-llvmjit-${SQLITE_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"

fi

# Clean
docker rmi $IMAGE_TAG
