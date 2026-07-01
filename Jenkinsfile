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

        stage('Checkout Source') {
            steps {
                checkout scm

                sh '''
                    echo "===== SOURCE ====="
                    pwd
                    ls -la
                '''
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "===== TOOLS ====="
                    git --version
                    docker --version
                    terraform version
                    aws --version
                '''
            }
        }

        stage('AWS Identity Check') {
            steps {
               withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=us-east-1

                        aws sts get-caller-identity
                    '''
}
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    dir("${TF_DIR}") {
                        sh '''
                            echo "===== TERRAFORM INIT ====="
                            terraform init

                            echo "===== TERRAFORM VALIDATE ====="
                            terraform validate

                            echo "===== TERRAFORM PLAN ====="
                            terraform plan -out=tfplan

                            echo "===== TERRAFORM APPLY ====="
                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    env.EC2_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Wait for EC2') {
            steps {
                sleep(time: 60, unit: 'SECONDS')
            }
        }

        stage('Deploy Application to EC2') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP} '
                            mkdir -p ~/app
                        '

                        scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -r ${APP_DIR}/* \
                            ${SSH_USER}@${EC2_IP}:~/app/
                    """
                }
            }
        }

        stage('Build & Run Docker on EC2') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP} '
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

        stage('Health Check') {
            steps {
                sh """
                    echo "=========================="
                    echo "App URL: http://${EC2_IP}:5000"
                    echo "=========================="

                    curl --fail http://${EC2_IP}:5000 || true
                """
            }
        }
    }

    post {
        success {
            echo "PIPELINE SUCCESS"
            echo "APP: http://${EC2_IP}:5000"
        }

        failure {
            echo "PIPELINE FAILED"
        }

        always {
            cleanWs()
        }
    }
}