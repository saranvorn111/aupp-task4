pipeline {

    agent {
        docker {
            image 'hashicorp/terraform:1.7.5'
            args '--entrypoint="" -u root'
        }
    }

    environment {

        APP_DIR = "NodeAPI"
        TF_DIR  = "NodeAPI/terraform"

        IMAGE_NAME = "nodeapi"
        IMAGE_TAG  = "latest"

        AWS_DEFAULT_REGION = "us-east-1"
        TF_IN_AUTOMATION   = "true"

        EC2_USER = "ec2-user"
        APP_URL_FILE = "/tmp/app_url.txt"
    }

    parameters {
        booleanParam(
            name: 'REPLACE_EC2_INSTANCE',
            defaultValue: false,
            description: 'Recreate EC2 instance if needed'
        )
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Tools') {
            steps {
                sh '''
                    apk add --no-cache aws-cli curl openssh-client
                    aws --version
                    terraform version
                '''
            }
        }

        stage('Terraform Deploy') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {

                    dir("${TF_DIR}") {

                        sh '''
                            set -eux

                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            aws sts get-caller-identity

                            terraform init -input=false
                            terraform validate

                            if [ "$REPLACE_EC2_INSTANCE" = "true" ]; then
                                terraform plan -input=false -out=tfplan -replace="aws_instance.web"
                            else
                                terraform plan -input=false -out=tfplan
                            fi

                            terraform apply -input=false -auto-approve tfplan

                            terraform output -raw public_ip > /tmp/ec2_ip.txt
                            terraform output -raw website_url > /tmp/app_url.txt

                            echo "EC2 IP: $(cat /tmp/ec2_ip.txt)"
                            echo "APP URL: $(cat /tmp/app_url.txt)"
                        '''
                    }
                }
            }
        }

        stage('Verify EC2 Deploy') {
            steps {
                withCredentials([
                    file(credentialsId: 'vockey', variable: 'SSH_KEY_FILE')
                ]) {

                    sh '''
                        set -eux

                        EC2_IP=$(cat /tmp/ec2_ip.txt)
                        APP_URL=$(cat /tmp/app_url.txt)

                        cp "$SSH_KEY_FILE" /tmp/key.pem
                        chmod 600 /tmp/key.pem

                        SSH_OPTS="-i /tmp/key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=30"

                        echo "Waiting for EC2 SSH..."

                        for i in $(seq 1 15); do
                            if ssh $SSH_OPTS ec2-user@$EC2_IP "echo connected"; then
                                break
                            fi
                            sleep 15
                        done

                        ssh $SSH_OPTS ec2-user@$EC2_IP << 'EOF'
                            set -eux

                            sudo systemctl status docker || true
                            sudo docker ps || true
EOF

                        echo "Testing HTTP endpoint..."

                        for i in $(seq 1 20); do
                            if curl -fsS "$APP_URL" >/dev/null; then
                                echo "App running at $APP_URL"
                                exit 0
                            fi
                            sleep 10
                        done

                        echo "App failed to start"
                        exit 1
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/tfplan', allowEmptyArchive: true
        }

        success {
            echo "PIPELINE SUCCESS"
        }

        failure {
            echo "PIPELINE FAILED"
        }
    }
}