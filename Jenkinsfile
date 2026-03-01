pipeline {
    agent any

    tools {
        maven 'maven3'
        dockerTool 'docker'
    }

    environment {
        AWS_REGION = "ap-south-1"
        AWS_ACCOUNT_ID = "410687236364"
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/newjava-app"
        IMAGE_TAG = "master-${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                sh """
                    mvn clean package -DskipTests
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${FULL_IMAGE_NAME} .
                """
            }
        }

        stage('Login to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh """
                    echo "Pushing image: ${FULL_IMAGE_NAME}"
                    docker push ${FULL_IMAGE_NAME}
                """
            }
        }

        stage('Update Deployment YAML (GitOps)') {
            steps {
                sh """
                    echo "===== Updating deployment.yaml ====="
                    sed -i 's|image: .*|image: ${FULL_IMAGE_NAME}|' git-app/deployment.yaml

                    echo "===== Updated deployment.yaml ====="
                    cat git-app/deployment.yaml
                """

                sh """
                    git config user.name "jenkins"
                    git config user.email "jenkins@local"

                    git add git-app/deployment.yaml
                    git commit -m "Update image to ${IMAGE_TAG}"
                    git push origin master
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully"
        }

        failure {
            echo "❌ Pipeline failed"
        }

        always {
            sh """
                docker image prune -f
            """
        }
    }
}
