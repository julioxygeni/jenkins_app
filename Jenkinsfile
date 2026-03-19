pipeline {
    agent any

    tools {
        maven 'Maven 3.9'
        jdk 'JDK 17'
    }

    environment {
        APP_NAME = 'jenkins-app'
        APP_VERSION = '1.0.0'
        JAR_FILE = "target/${APP_NAME}-${APP_VERSION}.jar"
        DEPLOY_DIR = '/opt/apps/jenkins-app'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
                echo "Branch: ${env.BRANCH_NAME ?: 'local'}"
                echo "Commit: ${env.GIT_COMMIT ?: 'N/A'}"
            }
        }

        stage('Build') {
            steps {
                echo "Building application..."
                sh 'mvn clean package -DskipTests'
                echo "Build complete: ${JAR_FILE}"
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo "Deploying to ${DEPLOY_DIR}..."
                sh """
                    mkdir -p ${DEPLOY_DIR}
                    cp ${JAR_FILE} ${DEPLOY_DIR}/${APP_NAME}.jar

                    # Stop existing instance if running
                    pkill -f "${APP_NAME}.jar" || true
                    sleep 2

                    # Start application in background
                    nohup java -jar ${DEPLOY_DIR}/${APP_NAME}.jar \
                        > ${DEPLOY_DIR}/app.log 2>&1 &

                    echo "App started. Checking health..."
                    sleep 5
                    curl -f http://localhost:8080/health || exit 1
                    echo "Deploy successful!"
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
        always {
            cleanWs()
        }
    }
}
