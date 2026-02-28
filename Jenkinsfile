pipeline {
    agent any

    tools {
        maven 'maven-3.9'
        jdk 'jdk-17'
    }

    parameters {
        choice(
            name: 'BRANCH',
            choices: ['master', 'dev', 'release'],
            description: 'Select Git branch'
        )
    }

    environment {
        SONAR_SERVER = 'sonarqube-server'
        SONAR_PROJECT_KEY = 'newjava-app'
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '410687236364'
        ECR_REPO_NAME = 'newjava-app'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        // Use double quotes to ensure Jenkins expands the variables
        IMAGE_TAG = "${params.BRANCH}-${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: "${params.BRANCH}",
                    url: 'https://github.com/charankt03/newjava-application.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // withSonarQubeEnv handles the server URL and auth automatically 
                // if configured correctly in "Manage Jenkins"
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${FULL_IMAGE_NAME} ."
            }
        }

        stage('Login & Push Image to ECR') {
            steps {
                // Using Jenkins variables instead of hardcoding the ID again
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                docker push ${FULL_IMAGE_NAME}
                """
            }
        }

        stage('Update GitOps Repo (ArgoCD)') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh """
                        rm -rf gitops
                        git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/charankt03/newjava-gitops.git gitops
                        cd gitops/apps/newjava-app
                        
                        # Corrected sed: uses | as delimiter to avoid path slash conflicts
                        sed -i "s|image: .*|image: ${FULL_IMAGE_NAME}|g" deployment.yaml

                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins CI"
                        git add deployment.yaml
                        if git diff --quiet && git diff --staged --quiet; then
                            echo "No changes to commit"
                        else
                            git commit -m "Update image to ${IMAGE_TAG}"
                            git push origin main
                        fi
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD completed successfully: ${FULL_IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        cleanup {
            // Be careful with -af in production; it removes all unused images
            sh 'docker system prune -f || true'
        }
    }
}
