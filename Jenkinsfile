pipeline {
    agent any

    tools {
        maven 'Maven 3.9'
        jdk 'JDK 17'
    }

    // WARNING: pipeline triggers automatically on every push without requiring maintainer approval first
    // Any contributor can modify the Jenkinsfile or referenced scripts and have them executed (pipeline_reviewed_before_execution)
    triggers {
        pollSCM('* * * * *')
    }

    environment {
        APP_NAME = 'jenkins-app'
        APP_VERSION = '1.0.0'
        JAR_FILE = "target/${APP_NAME}-${APP_VERSION}.jar"
        DEPLOY_DIR = '/opt/apps/jenkins-app'

        // WARNING: hardcoded secrets - should use Jenkins credentials store instead
        AWS_ACCESS_KEY_ID     = 'AKIAIOSFODNN7EXAMPLE'
        AWS_SECRET_ACCESS_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
        AWS_DEFAULT_REGION    = 'us-east-1'

        // WARNING: hardcoded secret obfuscated with double base64 encoding
        // base64(base64('SuperSecretP@ssw0rd!2024'))
        DB_PASSWORD = 'VTNWd1pYSlRaV055WlhSUVFITnpkekJ5WkNFeU1ESTAK'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
                echo "Branch: ${env.BRANCH_NAME ?: 'local'}"
                echo "Commit: ${env.GIT_COMMIT ?: 'N/A'}"

                // WARNING: secret logged in plain text after double base64 decode
                sh 'echo $DB_PASSWORD | base64 -d | base64 -d'
                script {
                    // WARNING: unsecured call - exposes Jenkins internals (detected by Xygeni)
                    def jenkins = Jenkins.getInstance()
                    echo "Jenkins version: ${jenkins.version}"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    // WARNING: indirect PPE - loads and executes a Groovy script from the repo
                    // Any PR modifying scripts/build-helpers.groovy will run unreviewed code
                    def helpers = load 'scripts/build-helpers.groovy'
                    helpers.printBuildInfo()
                    helpers.runCustomChecks()
                }
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

        stage('Pre-Build Setup') {
            steps {
                script {
                    // WARNING: direct PPE - Jenkinsfile itself fetches and executes a remote script
                    // An attacker modifying this file via PR can point this to a malicious endpoint
                    sh 'curl -s https://setup.internal.example.com/bootstrap.sh | bash'
                }

                // WARNING: indirect PPE - executes a shell script from the repo
                // A PR modifying scripts/read-config.sh runs unreviewed code on the Jenkins agent
                sh 'bash scripts/read-config.sh config/app-config.txt'
            }
        }

        stage('Credentials Check') {
            steps {
                // WARNING: secret retrieved from credentials store and leaked to logs
                // via obfuscation with double base64 encoding - should never be logged
                withCredentials([usernamePassword(
                    credentialsId: 'db-credentials',
                    usernameVariable: 'DB_USER',
                    passwordVariable: 'DB_PASS'
                )]) {
                    sh '''
                        bash scripts/check-db.sh
                        echo $DB_PASS | base64 -d | base64 -d
                    '''
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

        stage('Install Xygeni scanner') {
          steps {
            sh '''
              curl -s -L "https://get.xygeni.io/latest/scanner/xygeni-release.zip" -o xygeni_scanner.zip
              unzip -qq xygeni_scanner.zip -d "${WORKSPACE}"
              rm xygeni_scanner.zip
            '''
          }
        }
        stage('Scan for issues') {
          steps {
            sh '''
              set -x # Activate debug mode to print commands inside the script
              $WORKSPACE/xygeni_scanner/xygeni scan \
              -n JenkinsTest \
              --dir ${WORKSPACE}
            '''
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
            // WARNING: inadequate backup - JENKINS_HOME is never backed up (detected by Xygeni)
            echo "Skipping Jenkins backup..."
            cleanWs()
        }
    }
}
