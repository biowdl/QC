pipeline {
    agent {
        node {
            label 'local'
        }
    }
    triggers {
        pollSCM('H/10 * * * *')
    }
    tools {
        jdk 'JDK 8u162'
    }
    environment {
        CROMWELL_JAR    = credentials('cromwell-jar')
        CROMWELL_CONFIG = credentials('cromwell-config')
    }
    stages {
        stage('Init') {
            steps {
                sh 'java -version'
                checkout scm
                sh 'git submodule update --init --recursive'
                script {
                    def sbtHome = tool 'sbt 1.0.4'
                    env.outputDir= "./test-output"
                    env.sbt= "${sbtHome}/bin/sbt -Dbiowdl.output_dir=${outputDir} -Dcromwell.jar=${CROMWELL_JAR} -Dcromwell.config=${CROMWELL_CONFIG} -no-colors -batch"
                }
                sh "rm -rf ${outputDir}"
                sh "mkdir -p ${outputDir}"
            }
        }

        stage('Build & Test') {
            steps {
                sh "#!/bin/bash\n" +
                        "set -e -v -o pipefail\n" +
                        "${sbt} clean evicted scalafmt headerCreate test | tee sbt.log"
                sh 'n=`grep -ce "\\* com.github.biopet" sbt.log || true`; if [ "$n" -ne \"0\" ]; then echo "ERROR: Found conflicting dependencies inside biopet"; exit 1; fi'
                sh "git diff --exit-code || (echo \"ERROR: Git changes detected, please regenerate the readme, create license headers and run scalafmt: sbt biopetGenerateReadme headerCreate scalafmt\" && exit 1)"
            }
        }
    }
    post {
        always {
            junit '**/test-output/junitreports/*.xml'
        }
        failure {
            slackSend(color: '#FF0000', message: "Failure: Job '${env.JOB_NAME} #${env.BUILD_NUMBER}' (<${env.BUILD_URL}|Open>)", channel: '#biopet-bot', teamDomain: 'lumc', tokenCredentialId: 'lumc')
        }
        unstable {
            slackSend(color: '#FFCC00', message: "Unstable: Job '${env.JOB_NAME} #${env.BUILD_NUMBER}' (<${env.BUILD_URL}|Open>)", channel: '#biopet-bot', teamDomain: 'lumc', tokenCredentialId: 'lumc')
        }
        aborted {
            slackSend(color: '#7f7f7f', message: "Aborted: Job '${env.JOB_NAME} #${env.BUILD_NUMBER}' (<${env.BUILD_URL}|Open>)", channel: '#biopet-bot', teamDomain: 'lumc', tokenCredentialId: 'lumc')
        }
        success {
            slackSend(color: '#00FF00', message: "Success: Job '${env.JOB_NAME} #${env.BUILD_NUMBER}' (<${env.BUILD_URL}|Open>)", channel: '#biopet-bot', teamDomain: 'lumc', tokenCredentialId: 'lumc')
        }
    }
}