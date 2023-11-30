def NODE_NAME = 'AWS_Instance_CentOS'
def MAIL_TO = '$DEFAULT_RECIPIENTS'
def BRANCH_NAME = 'Branch [' + env.BRANCH_NAME + ']'
def BUILD_INFO = 'Jenkins job: ' + env.BUILD_URL + '\n'

def BRANCH_PGSPIDER = 'port16.0'
def make_check_test(String target, String version) {
    def prefix = ""
    script {
        if (version != "") {
            version = "-" + version
        }
        if (target == "PGSpider") {
            prefix = "REGRESS_PREFIX=PGSpider"
        }
    }
    catchError() {
        sh """
            rm -rf make_check_existed_test.out || true
            docker exec postgresserver_multi_for_sqlite_existed_test /bin/bash -c 'su -c "/home/test/sqlite_existed_test.sh ${env.GIT_BRANCH} ${target}${version}" postgres'
            docker exec -w /home/postgres/${target}${version}/contrib/sqlite_fdw postgresserver_multi_for_sqlite_existed_test /bin/bash -c 'su -c "make clean && make ${prefix} && export LANGUAGE="en_US.UTF-8" && export LANG="en_US.UTF-8" && export LC_ALL="en_US.UTF-8" && make check ${prefix} | tee make_check_existed_test.out" postgres'
            docker cp postgresserver_multi_for_sqlite_existed_test:/home/postgres/${target}${version}/contrib/sqlite_fdw/results/ results_${target}${version}
            docker cp postgresserver_multi_for_sqlite_existed_test:/home/postgres/${target}${version}/contrib/sqlite_fdw/make_check_existed_test.out make_check_existed_test.out
        """
    }
    script {
        status = sh(returnStatus: true, script: "grep -q 'All [0-9]* tests passed' 'make_check_existed_test.out'")
        if (status != 0) {
            unstable(message: "Set UNSTABLE result")
            sh "docker cp postgresserver_multi_for_sqlite_existed_test:/home/postgres/${target}${version}/contrib/sqlite_fdw/regression.diffs regression.diffs"
            sh 'cat regression.diffs || true'
            updateGitlabCommitStatus name: 'make_check', state: 'failed'
        } else {
            updateGitlabCommitStatus name: 'make_check', state: 'success'
        }
    }
}

pipeline {
    agent {
        node {
            label NODE_NAME
        }
    }
    options {
        gitLabConnection('GitLabConnection')
    }
    triggers {
        gitlab(
            triggerOnPush: true,
            triggerOnMergeRequest: false,
            triggerOnClosedMergeRequest: false,
            triggerOnAcceptedMergeRequest: true,
            triggerOnNoteRequest: false,
            setBuildDescription: true,
            branchFilterType: 'All'
        )
    }
    stages {
        stage('Start_containers_Existed_Test') {
            steps {
                script {
                    if (env.GIT_URL != null) {
                        BUILD_INFO = BUILD_INFO + "Git commit: " + env.GIT_URL.replace(".git", "/commit/") + env.GIT_COMMIT + "\n"
                    }
                    sh 'rm -rf results_* || true'
                }
                catchError() {
                    sh """
                        docker run -d --name postgresserver_multi_for_sqlite_existed_test postgresserver
                    """
                }
            }
            post {
                failure {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Start Containers FAILED ' + BRANCH_NAME, body: BUILD_INFO + '${BUILD_LOG, maxLines=200, escapeHtml=false}', to: "${MAIL_TO}", attachLog: false
                    updateGitlabCommitStatus name: 'Build', state: 'failed'
                }
                success {
                    updateGitlabCommitStatus name: 'Build', state: 'success'
                }
            }
        }
        stage('make_check_FDW_Test_With_Postgres_12_16') {
            steps {
                catchError() {
                   make_check_test("postgresql","12.16")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on v12.16 FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        stage('make_check_FDW_Test_With_Postgres_13_12') {
            steps {
                catchError() {
                   make_check_test("postgresql","13.12")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on v13.12 FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        stage('make_check_FDW_Test_With_Postgres_14_9') {
            steps {
                catchError() {
                   make_check_test("postgresql","14.9")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on v14.9 FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        stage('make_check_FDW_Test_With_Postgres_15_4') {
            steps {
                catchError() {
                    make_check_test("postgresql", "15.4")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on v15.4 FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        stage('make_check_FDW_Test_With_Postgres_16_0') {
            steps {
                catchError() {
                    make_check_test("postgresql", "16.0")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on v16.0 FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        stage('Build_PGSpider_For_FDW_Test') {
            steps {
                catchError() {
                    sh """
                        docker exec postgresserver_multi_for_sqlite_existed_test /bin/bash -c 'su -c "/home/test/initialize_pgspider_existed_test.sh $BRANCH_PGSPIDER" postgres'
                    """
                }
            }
            post {
                failure {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Build PGSpider FAILED ' + BRANCH_NAME, body: BUILD_INFO + '${BUILD_LOG, maxLines=200, escapeHtml=false}', to: "${MAIL_TO}", attachLog: false
                    updateGitlabCommitStatus name: 'Build_PGSPider', state: 'failed'
                }
                success {
                    updateGitlabCommitStatus name: 'Build_PGSPider', state: 'success'
                }
            }
        }
        stage('make_check_FDW_Test_With_PGSpider') {
            steps {
                catchError() {
                   make_check_test("PGSpider","")
                }
            }
            post {
                unstable {
                    emailext subject: '[CI SQLITE_FDW] EXISTED_TEST: Result make check on PGSpider FAILED ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
    }
    post {
        success  {
            script {
                prevResult = 'SUCCESS'
                if (currentBuild.previousBuild != null) {
                    prevResult = currentBuild.previousBuild.result.toString()
                }
                if (prevResult != 'SUCCESS') {
                    emailext subject: '[CI SQLITE_FDW] SQLITE_Test BACK TO NORMAL on ' + BRANCH_NAME, body: BUILD_INFO  + '${FILE,path="make_check_existed_test.out"}', to: "${MAIL_TO}", attachLog: false
                }
            }
        }
        always {
            sh """
                docker stop postgresserver_multi_for_sqlite_existed_test
                docker rm postgresserver_multi_for_sqlite_existed_test
            """
        }
    }
}
