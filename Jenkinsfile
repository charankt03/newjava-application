pipeline {
    agent any

    tools {
        maven 'maven-3.9'
        jdk 'jdk-11'
    }

    parameters {
        choice(
            name: 'BRANCH',
            choices: ['main', 'dev', 'release'],
            description: 'Select Git branch'
        )
    }

    environment {
        SONAR_SERVER = 'sonarqube-server'
        SONAR_PROJECT_KEY = 'myapp'

        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '420838436623'
        ECR_REPO_NAME = 'hello-java'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        IMAGE_TAG = "${params.BRANCH}-${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: "${params.BRANCH}",
                    url: 'https://github.com/kskarthik172/myapp-source.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    withCredentials([string(
                        credentialsId: 'sonar-token',
                        variable: 'SONAR_TOKEN'
                    )]) {
                        sh """
                            mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${FULL_IMAGE_NAME} .
                """
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker push ${FULL_IMAGE_NAME}
                """
            }
        }

        stage('Update Kubernetes Manifest') {
            steps {
                sh """
                    sed -i 's|image: .*|image: ${FULL_IMAGE_NAME}|g' k8s/deployment.yaml
                """
            }
        }

        stage('Commit & Push Updated YAML') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh """
                        git config user.email "jenkins@local"
                        git config user.name "jenkins"

                        git add k8s/deployment.yaml
                        git commit -m "Updated image to ${IMAGE_TAG}" || echo "No changes"

                        git push https://${GIT_USER}:${GIT_PASS}@github.com/kskarthik172/myapp-source.git HEAD:${params.BRANCH}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "🚀 Full CI/CD + GitOps Deployment Completed!"
            echo "Deployed Image: ${FULL_IMAGE_NAME}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
