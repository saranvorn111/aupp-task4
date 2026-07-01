pipeline {
    agent any

    environment {
        IMAGE_NAME = "YOUR_DOCKER_USERNAME/nodeapi"
        IMAGE_TAG = "latest"

        TF_DIR = "terraform"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('NodeAPI') {
                    sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                    docker push $IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("$TF_DIR") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("$TF_DIR") {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Deploy') {

            steps {

                script {

                    def ip = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${ip} '
                        docker pull ${IMAGE_NAME}:${IMAGE_TAG}

                        docker stop nodeapi || true
                        docker rm nodeapi || true

                        docker run -d \
                            --name nodeapi \
                            -p 5000:5000 \
                            ${IMAGE_NAME}:${IMAGE_TAG}
                    '
                    """
                }

            }

        }

    }

}