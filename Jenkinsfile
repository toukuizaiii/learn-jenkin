pipeline {
    agent {
        docker {
            image 'golang:1.26'
        }
    }

    environment {
        GOCACHE = '/tmp/go-build'
        GOPATH = '/tmp/go'
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
                sh 'go build -o server .'
                archiveArtifacts artifacts: 'server', fingerprint: true
            }
        }
    }
}
