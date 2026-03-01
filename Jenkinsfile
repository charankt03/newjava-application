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

        IMAGE_TAG = "${params.BRANCH}-${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

        AWS_PAGER = ""
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
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=${SONAR_PROJECT_KEY}'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "Building Docker Image: ${FULL_IMAGE_NAME}"
                    docker build -t ${FULL_IMAGE_NAME} .
                """
            }
        }

        stage('Login & Push Image to ECR') {
            steps {
                sh """
                    set -e
                    aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker push ${FULL_IMAGE_NAME}
                """
            }
        }

        stage('Update Deployment YML (GitOps)') {
            steps {
                sh """
                    echo "===== Updating deployment.yml ====="

                    sed -i "s|image: .*|image: ${FULL_IMAGE_NAME}|" git-app/deployment.yml

                    echo "===== Updated deployment.yml ====="
                    cat git-app/deployment.yml
                """

                sh """
                    git config user.name "jenkins"
                    git config user.email "jenkins@local"

                    git add git-app/deployment.yml

                    git commit -m "Update image to ${IMAGE_TAG}" || echo "No changes to commit"

                    git push origin ${params.BRANCH}
                """
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD completed successfully"
            echo "📦 Image pushed: ${FULL_IMAGE_NAME}"
            echo "🚀 Argo CD will auto-sync"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        cleanup {
            sh 'docker image prune -f || true'
        }
    }
}
