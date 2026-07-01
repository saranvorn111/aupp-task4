pipeline {

    agent any

    environment {
        APP_DIR = "NodeAPI"
        TF_DIR  = "NodeAPI/terraform"

        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    echo "TOOLS CHECK"
                    terraform version
                    aws --version || true
                    docker --version || true
                '''
            }
        }

        stage('AWS Authentication Test (CRITICAL)') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    sh '''
                        set -eux

                        export AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=us-east-1

                        aws sts get-caller-identity
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {
                        sh '''
                            set -eux

                            export AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1

                            terraform init -input=false
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
                            set -eux

                            export AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1

                            terraform validate
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
                            set -eux

                            export AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=us-east-1

                            terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Get Output') {
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

        stage('Deploy App') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@${EC2_IP} 'mkdir -p ~/app'

                        scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -r ${APP_DIR}/* \
                        ${SSH_USER}@${EC2_IP}:~/app/
                    """
                }
            }
        }

        stage('Run Docker') {
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

                            sudo docker build -t nodeapi:latest .
                            sudo docker run -d -p 5000:5000 --name nodeapi nodeapi:latest
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "http://${EC2_IP}:5000"
                    curl --fail http://${EC2_IP}:5000 || true
                """
            }
        }
    }

    post {
        always {
            cleanWs()
        }

        success {
            echo "PIPELINE SUCCESS"
        }

        failure {
            echo "PIPELINE FAILED"
        }
    }
}