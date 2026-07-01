pipeline {

    agent any

    environment {

        APP_DIR = "NodeAPI"
        TF_DIR  = "NodeAPI/terraform"

        IMAGE_NAME = "nodeapi"
        IMAGE_TAG  = "latest"

        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {

        stage('Stage 1 - Checkout Source') {

            steps {

                checkout scm

                sh '''
                    echo "========== CHECKOUT =========="
                    pwd
                    ls -la
                    tree -L 2
                '''

            }

        }

        stage('Stage 2 - Verify Tools') {

            steps {

                sh '''
                    echo "========== VERIFY TOOLS =========="

                    git --version
                    docker --version
                    terraform version
                    aws --version

                    echo "================================="
                '''

            }

        }

        stage('Stage 3 - Terraform Init') {

            steps {

                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            terraform init
                        '''

                    }

                }

            }

        }

        stage('Stage 4 - Terraform Validate') {

            steps {

                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            terraform validate
                        '''

                    }

                }

            }

        }

        stage('Stage 5 - Terraform Plan') {

            steps {

                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            terraform plan
                        '''

                    }

                }

            }

        }

        stage('Stage 6 - Terraform Apply') {

            steps {

                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            terraform apply -auto-approve tfplan
                        '''

                    }

                }

            }

        }

        stage('Stage 7 - Get EC2 Public IP') {

            steps {

                script {

                    env.EC2_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "================================="
                    echo "EC2 IP : ${env.EC2_IP}"
                    echo "================================="

                }

            }

        }

        stage('Stage 8 - Wait For EC2') {

            steps {

                echo "Waiting for EC2..."

                sleep(time: 60, unit: 'SECONDS')

            }

        }

        stage('Stage 9 - Copy Application') {

            steps {

                withCredentials([

                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )

                ]) {

                    sh """

                        ssh -i ${SSH_KEY} \
                        -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${EC2_IP} \
                        "mkdir -p ~/app"

                        scp -i ${SSH_KEY} \
                        -o StrictHostKeyChecking=no \
                        -r ${APP_DIR}/* \
                        ${SSH_USER}@${EC2_IP}:~/app/

                    """

                }

            }

        }

        stage('Stage 10 - Build & Run Docker') {

            steps {

                withCredentials([

                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )

                ]) {

                    sh """

                        ssh -i ${SSH_KEY} \
                        -o StrictHostKeyChecking=no \
                        ${SSH_USER}@${EC2_IP} '

                            cd ~/app

                            sudo docker stop nodeapi || true

                            sudo docker rm nodeapi || true

                            sudo docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

                            sudo docker run -d \
                                --name nodeapi \
                                -p 5000:5000 \
                                ${IMAGE_NAME}:${IMAGE_TAG}

                        '

                    """

                }

            }

        }

        stage('Stage 11 - Health Check') {

            steps {

                sh """

                    echo "==================================="

                    echo "Application URL"

                    echo "http://${EC2_IP}:5000"

                    echo "==================================="

                    curl --fail http://${EC2_IP}:5000 || true

                """

            }

        }

    }

    post {

        success {

            echo "================================="
            echo "PIPELINE SUCCESS"
            echo "Application URL:"
            echo "http://${EC2_IP}:5000"
            echo "================================="

        }

        failure {

            echo "================================="
            echo "PIPELINE FAILED"
            echo "================================="

        }

        always {

            cleanWs()

        }

    }

}