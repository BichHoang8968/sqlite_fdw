Usage of creating sqlite_fdw RPM packages
=====================================

This document is about how to create and publish rpm packages of sqlite_fdw to Benzaiten. 
- It provided 2 tools to create SQLite FDW RPMs.  
Both tools use the sqlite_fdw.spec file from the Postgres community as a base.  
Community's spec file will download source code of sqlite_fdw from Internet and build it. Therefore, if you wants to build rpm file of a stable version of sqlite_fdw automatically, you can use community's spec file. In case of you already have source code of sqlite_fdw (possibly with some custom modification), and want to build rpm file from current source code, you can use this tool. Refer [pgrpms](https://git.postgresql.org/gitweb/?p=pgrpms.git;a=blob;f=rpm/redhat/main/non-common/sqlite_fdw/main/sqlite_fdw.spec;h=864e7ce58825eea3a7658b55305fb1365d51e917;hb=df216ffca23020a436ca964a294e229a9073f4a8)
	- One is for creating RPMs with [PGSpider](#creating-sqlite_fdw-rpm-packages-for-pgspider).
		- The PGSpider RPM package is required. It must be released on PGSpider repository first.
		- The PGSpider RPM package have released on PGSpider [package registry](https://tccloud2.toshiba.co.jp/swc/gitlab/db/PGSpider/-/packages/22).
	- Another is for creating RPMs with [PostgreSQL](#creating-sqlite_fdw-rpm-packages-for-postgresql).
- Additionally, we also provide Gitlab CI/CD pipeline for creating sqlite_fdw RPM packages for [PGSpider](#usage-of-run-cicd-pipeline).


Environment for creating rpm of sqlite_fdw
=====================================
The description below is used in the specific Linux distribution RockyLinux8.
1. Docker
	- Install Docker
		```sh
		sudo yum install -y yum-utils
		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
		sudo yum install -y docker-ce docker-ce-cli containerd.io
		sudo systemctl enable docker
		sudo systemctl start docker
		```
	- Enable the currently logged in user to use docker commands
		```sh
		sudo gpasswd -a $(whoami) docker
		sudo chgrp docker /var/run/docker.sock
		sudo systemctl restart docker
		```
	- Proxy settings (If your network must go through a proxy)
		```sh
		sudo mkdir -p /etc/systemd/system/docker.service.d
		sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
		[Service]
		Environment="HTTP_PROXY=http://proxy:port/"
		Environment="HTTPS_PROXY=http://proxy:port/"
		Environment="NO_PROXY=localhost,127.0.0.1"
		EOF
		sudo systemctl daemon-reload
		sudo systemctl restart docker
		```
2. Get the required files  
	```sh
	git clone https://tccloud2.toshiba.co.jp/swc/gitlab/db/sqlite_fdw.git
	```

Creating sqlite_fdw rpm packages for PGSpider
=====================================
1. Preconditions
	PGSpider RPM packages are must-have packages. They need to be released first on the [pgspider](https://tccloud2.toshiba.co.jp/swc/gitlab/db/PGSpider/-/packages/22) repository.
2. File used here
	- rpm/deps/sqlite.spec
	- rpm/sqlite_fdw_spec_pgspider.patch
	- rpm/env_rpmbuild.conf
	- rpm/Dockerfile_rpm
	- rpm/create_rpm_binary_with_PGSpider.sh
3. Configure `rpm/env_rpmbuild.conf` file
	- Configure proxy
		```sh
		proxy=http://username:password@proxy:port
		no_proxy=localhost,127.0.0.1
		```
	- Configure the registry location to publish the package and version of the packages
		```sh
		location=gitlab 					# Fill in <gitlab> or <github>. In this project, please use <gitlab>
		ACCESS_TOKEN=						# Fill in the Access Token for authentication purposes to publish rpm packages to Package Registry
		API_V4_URL=							# Fill in API v4 URL of this repo. In this project please use <https://tccloud2.toshiba.co.jp/swc/gitlab/api/v4>
		SQLITE_FDW_PROJECT_ID=				# Fill in the ID of the sqlite_fdw project.		
		PGSPIDER_PROJECT_ID=				# Fill in the ID of the PGSpider project to get PGSpider rpm packages
		PGSPIDER_RPM_ID=					# Fill in the ID of PGSpider rpm packages
		PGSPIDER_BASE_POSTGRESQL_VERSION=16 # Base Postgres version of PGSpider
		PGSPIDER_RELEASE_VERSION=4.0.0-1	# PGSpider rpm packages version
		PACKAGE_RELEASE_VERSION=1			# The number of times this version of the sqlite_fdw has been packaged.
		SQLITE_VERSION=3.42.0				# Release version of SQLite. You can check in: https://www.sqlite.org/chronology.html.
		SQLITE_YEAR=2023					# The year that the sqlite version was released. For example: 2023 for version 3.42.0. You can check in: https://www.sqlite.org/chronology.html.
		SQLITE_FDW_RELEASE_VERSION=2.4.0	# Version of sqlite_fdw rpm package
		```
4. Build execution
	```sh
	chmod +x rpm/create_rpm_binary_with_PGSpider.sh
	./rpm/create_rpm_binary_with_PGSpider.sh
	```
5. Confirmation after finishing executing the script
	- Terminal displays a success message. 
		```
		{"message":"201 Created"}
		...
		{"message":"201 Created"}
		```
	- RPM Packages are stored on the Package Registry of its repository
		```sh
		Menu TaskBar -> Deploy -> Package Registry
		```

Creating sqlite_fdw rpm packages for PostgreSQL
=====================================
This tool will create sqlite_fdw rpm using PostgreSQL with the difference from PGSpider:
- Use script `create_rpm_binary_with_PostgreSQL.sh` instead of `create_rpm_binary_with_PGSpider.sh`.
- Use the parameters `POSTGRESQL_VERSION`, `PACKAGE_RELEASE_VERSION`, `SQLITE_VERSION`, `SQLITE_YEAR`, `SQLITE_FDW_RELEASE_VERSION`.
- The RPM packages after creation will be stored locally in the `fdw_rpm_with_postgres` directory and will not be uploaded to the repository.

1. File used here
	- rpm/deps/sqlite.spec
	- rpm/sqlite_fdw_spec_postgres.patch
	- rpm/env_rpmbuild.conf
	- rpm/Dockerfile_rpm
	- rpm/create_rpm_binary_with_PostgreSQL.sh
2. Configure `rpm/env_rpmbuild.conf` file
	- Configure proxy
		```sh
		proxy=http://username:password@proxy:port
		no_proxy=localhost,127.0.0.1
		```
	- Configure the registry location to publish the package and version of the packages
		```sh
		POSTGRESQL_VERSION=16.0-1					# PostgreSQL rpm packages version. You can check in: https://yum.postgresql.org/packages/.
		PACKAGE_RELEASE_VERSION=1					# The number of times this version of the sqlite_fdw has been packaged.
		SQLITE_VERSION=3.42.0						# Release version of SQLite. You can check in: https://www.sqlite.org/chronology.html.
		SQLITE_YEAR=2023							# The year that the sqlite version was released. For example: 2023 for version 3.42.0. You can check in: https://www.sqlite.org/chronology.html.
		SQLITE_FDW_RELEASE_VERSION=2.4.0			# Version of sqlite_fdw rpm package
		```
3. Build execution
	- Execute the script.
	```sh
	chmod +x rpm/create_rpm_binary_with_PostgreSQL.sh
	./rpm/create_rpm_binary_with_PostgreSQL.sh
	```
	- RPM Packages are stored on the `fdw_rpm_with_postgres` folder in the root directory.

Usage of Run CI/CD pipeline
=====================================
1. Go to Pipelines Screen
	```sh
	Menu TaskBar -> Build -> Pipelines
	```
2. Click `Run Pipeline` button  
![Alt text](images/BENZAITEN/pipeline_screen.PNG)
3. Choose `Branch` or `Tag` name
4. Provide `Access Token` through `Variables`
	- Input variable key: ACCESS_TOKEN
	- Input variable value: Your access token
5. Click `Run Pipeline` button  
![Alt text](images/BENZAITEN/run_pipeline.PNG)