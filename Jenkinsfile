// Jenkins 파이프라인의 시작을 선언합니다.
pipeline {
    // 사전 정의된 파드 템플릿을 사용하여 파드를 실행합니다.
    agent {
        label 'maven-agent'
    }

    // 파이프라인에서 사용할 환경 변수들을 정의합니다.
    // 수정해서 사용해 주세요.
    environment {
        // Harbor 레지스트리 관련 설정입니다.
        REGISTRY = 'harbor.jbnu.ac.kr'
        HARBOR_PROJECT = '<사용자 이름>'
        IMAGE_NAME = '<이미지 이름>'
        DOCKER_IMAGE = "${REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"
        DOCKER_CREDENTIALS_ID = 'harbor-credentials'
        SONAR_TOKEN = credentials('sonarqube-credentials')
        HARBOR_CREDENTIALS = credentials("${DOCKER_CREDENTIALS_ID}")
    }

    // 파이프라인의 각 단계를 정의합니다.
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Maven을 사용하여 프로젝트를 빌드하고 테스트하는 단계입니다.
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

        // SonarQube를 사용하여 코드 품질을 분석하는 단계입니다.
        // 수정해서 사용해 주세요.
        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withSonarQubeEnv('sonarqube') {
                        // sonar-scanner를 실행하여 코드 분석을 수행합니다.
                        sh """
                            sonar-scanner \\
                            -Dsonar.projectKey=<사용자이름-서비스> \\
                            -Dsonar.projectName=<사용자이름-서비스> \\
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

        // Docker 설정 파일 생성 단계 추가
        stage('Create Docker Config') {
            steps {
                script {
                    // Kaniko가 사용할 Docker 설정 파일 생성
                    sh """
                        mkdir -p /home/jenkins/agent/.docker
                        echo '{"auths":{"${REGISTRY}":{"username":"${HARBOR_CREDENTIALS_USR}","password":"${HARBOR_CREDENTIALS_PSW}"}}}' > /home/jenkins/agent/.docker/config.json
                        cat /home/jenkins/agent/.docker/config.json
                        cp /home/jenkins/agent/.docker/config.json /home/jenkins/agent/config.json
                    """
                    
                    // Kaniko가 사용할 볼륨에 Docker 설정 파일 복사
                    container('kaniko') {
                        sh """
                            mkdir -p /kaniko/.docker
                            cp /home/jenkins/agent/config.json /kaniko/.docker/config.json
                            ls -la /kaniko/.docker
                        """
                    }
                }
            }
        }

        // Kaniko를 사용하여 도커 이미지를 빌드하고 푸시하는 단계입니다.
        stage('Build and Push with Kaniko') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \\
                        --context=\$(pwd) \\
                        --dockerfile=\$(pwd)/Dockerfile \\
                        --destination=${DOCKER_IMAGE}:\${BUILD_NUMBER} \\
                        --cleanup
                    """
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
            sh 'rm -rf .git || true'
            sh 'find . -type f -not -path "*/\\.*" -delete || true'
            echo "Cleaning up workspace"
        }
    }
}