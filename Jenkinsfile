pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timeout(time: 15, unit: 'MINUTES')
    }

    environment {
        GOCACHE = '/tmp/go-build'
        GOPATH = '/tmp/go'
        APP_PORT = '8080'
        CONTAINER_NAME = 'learn-jenkin'
    }

    stages {
        stage('Verify and Build') {
            agent {
                docker {
                    image 'golang:1.26'
                    reuseNode true
                }
            }

            stages {
                stage('Check') {
                    steps {
                        sh 'go version'
                        sh 'go vet ./...'
                    }
                }

                stage('Test') {
                    steps {
                        sh 'go test ./...'
                    }
                }

                stage('Build') {
                    steps {
                        sh 'CGO_ENABLED=0 go build -trimpath -o server .'
                        archiveArtifacts artifacts: 'server', fingerprint: true
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t "learn-jenkin:${GIT_COMMIT}-${BUILD_NUMBER}" .'
            }
        }

        stage('Deploy') {
            when {
                allOf {
                    branch 'main'
                    not { changeRequest() }
                }
            }
            steps {
                input message: '确认部署到 Docker？', ok: '确认部署'

                sh '''
                    set -eu
                    export APP_IMAGE="learn-jenkin:${GIT_COMMIT}-${BUILD_NUMBER}"
                    sh scripts/deploy.sh
                '''
            }
        }
    }
}
