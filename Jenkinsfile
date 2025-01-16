pipeline {
    agent {
        label 'maven-agent' 
    }

    environment {
        REGISTRY = 'harbor.jdevops.co.kr'
        HARBOR_PROJECT = 'hyeongjun'
        IMAGE_NAME = 'spring'
        DOCKER_IMAGE = "${REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"
        DOCKER_CREDENTIALS_ID = 'harbor-credentials'
        SONAR_TOKEN = credentials('sonarqube-credentials')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                container('maven') {  
                    sh 'mvn clean package'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withSonarQubeEnv('sonarqube') {
                        sh """
                            sonar-scanner \\
                            -Dsonar.projectKey=hyeongjun-spring \\
                            -Dsonar.projectName=hyeongjun-spring \\
                            -Dsonar.sources=src/main/java/ \\
                            -Dsonar.java.binaries=target/classes/ \\
                            -Dsonar.junit.reportPaths=target/surefire-reports/ \\
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \\
                            -Dsonar.java.source=17 \\
                            -Dsonar.exclusions=**/generated-sources/** \\
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    script {
                        timeout(time: 2, unit: 'MINUTES') {
                            sh '''#!/bin/sh
                                until docker info >/dev/null 2>&1; do
                                    echo "Waiting for docker daemon..."
                                    sleep 2
                                done
                            '''
                        }

                        sh """
                            docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                        """
                    }
                }
            }
        }

        stage('Docker Push') {
            steps {
                container('docker') {
                    withDockerRegistry([credentialsId: DOCKER_CREDENTIALS_ID, url: "https://${REGISTRY}"]) {
                        sh """
                            docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Successfully built and pushed the image!'
        }
        failure {
            echo 'Failed to build or push the image'
        }
        always {
            container('docker') {
                script {
                    try {
                        sh """
                            docker rmi ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
                        """
                    } catch (Exception e) {
                        echo "Failed to remove docker image: ${e.message}"
                    }
                }
            }
        }
    }
}