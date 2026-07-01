pipeline {
    agent any

    environment {
        APP_DIR = "aupp-task4/NodeAPI/terraform"
        TF_DIR = "aupp-task4/terraform"

        IMAGE_NAME = "nodeapi"
        IMAGE_TAG  = "latest"

        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
                 sh '''
                    echo "===== Checkout Source Code ====="
                    tree
                    ls -la
                    echo "================================"
                '''
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "===== Verify Installed Tools ====="

                    git --version
                    docker --version
                    terraform version
                    aws --version
                    tree --version
                    echo "=================================="
                '''
            }
        }

        // stage('Build Docker Image') {
        //     steps {
        //         dir("${APP_DIR}") {
        //             sh """
        //                 docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        //             """
        //         }
        //     }
        // }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("NodeAPI/terraform") {

                        sh '''

                            tree
                            terraform init
                        '''

                    }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("NodeAPI/terraform") {

                        sh '''
                             pwd
                            ls -la
                            find . -name "*.tf"
                            terraform validate
                        '''

                    }

                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            pwd
                            ls -la
                            find . -name "*.tf"
                            cd /home/ubuntu/aupp-task4/NodeAPI/terraform
                            terraform plan -out=tfplan
                        '''

                    }

                }
            }
        }

        stage('Terraform Apply') {
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

        stage('Get EC2 Public IP') {
            steps {
                script {

                    env.EC2_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "=================================="
                    echo "EC2 Public IP: ${env.EC2_IP}"
                    echo "=================================="

                }
            }
        }

        stage('Wait for EC2') {
            steps {
                echo "Waiting 60 seconds for EC2 startup..."
                sleep(time: 60, unit: 'SECONDS')
            }
        }

        
    
            stage('Deploy Application') {
                steps {
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'ec2-ssh',
                            keyFileVariable: 'SSH_KEY',
                            usernameVariable: 'SSH_USER'
                        )
                    ]) {
                        sh """
                            scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -r ${APP_DIR}/* ${SSH_USER}@${EC2_IP}:~/app/

                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP} '
                                sudo apt update
                                sudo apt install -y docker.io
                                sudo systemctl enable docker
                                sudo systemctl start docker

                                cd ~/app
                                sudo docker build -t nodeapi .
                                sudo docker rm -f nodeapi || true
                                sudo docker run -d --name nodeapi -p 5000:5000 nodeapi
                            '
                        """
                    }
                }
            }

        stage('Health Check') {
            steps {

                sh """
                    echo "=================================="
                    echo "Application URL"
                    echo "http://${EC2_IP}:5000"
                    echo "=================================="

                    curl --connect-timeout 5 http://${EC2_IP}:5000 || true
                """

            }
        }

    }

    post {

        success {

            echo "======================================"
            echo "PIPELINE SUCCESS"
            echo "Application URL:"
            echo "http://${EC2_IP}:5000"
            echo "======================================"

        }

        failure {

            echo "======================================"
            echo "PIPELINE FAILED"
            echo "======================================"

        }

        always {

            cleanWs()

        }

    }

}