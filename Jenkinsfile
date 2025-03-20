pipeline {
    agent none

    options {
        timestamps()
    }

    stages {
        stage('Tests') {
            parallel {
                stage('Test Debug') {
                    agent {
                        label "zig-runner"
                    }
                    options {
                        timeout(time: 10, unit: 'MINUTES')
                    }
                    stages {
                        stage ('zig test debug') {
                            steps {
                                sh '''
                                zig build test -Doptimize=Debug -Dllvm=true
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            deleteDir()
                        }
                    }
                }
                stage('Test Release') {
                    agent {
                        label "zig-runner"
                    }
                    options {
                        timeout(time: 10, unit: 'MINUTES')
                    }
                    stages {
                        stage ('zig test release') {
                            steps {
                                sh '''
                                zig build test -Doptimize=ReleaseSafe -Dllvm=true
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            deleteDir()
                        }
                    }
                }
            }
        }
    }
}
