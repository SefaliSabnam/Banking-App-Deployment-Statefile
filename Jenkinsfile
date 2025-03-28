pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sefali26/banking-app"
        AWS_CREDENTIALS = 'AWS-Docker-Credentials'
        DOCKER_HUB_CREDENTIALS = 'DOCKER_HUB_TOKEN'
        TF_STATE_BUCKET = credentials('TF_STATE_BUCKET') // Fetching S3 bucket name securely
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    git credentialsId: 'github-token', url: 'https://github.com/SefaliSabnam/Banking-App-Deployment-Statefile.git', branch: env.BRANCH_NAME
                }
            }
        }

        stage('Ensure S3 Bucket for Terraform State') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh """
                        if aws s3 ls "s3://${env.TF_STATE_BUCKET}" > /dev/null 2>&1; then
                            echo "Terraform state bucket exists."
                        else
                            echo "Creating S3 bucket..."
                            aws s3 mb s3://${env.TF_STATE_BUCKET}
                        fi
                        """
                    }
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { env.BRANCH_NAME == 'main' } }
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_HUB_CREDENTIALS) {
                        sh "docker build -t ${DOCKER_IMAGE}:latest ."
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Pull Image from Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_HUB_CREDENTIALS) {
                        sh "docker pull ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }

        stage('Extract and Deploy Application') {
            when { expression { env.BRANCH_NAME == 'main' } }
            steps {
                script {
                    sh "docker create --name temp_container ${DOCKER_IMAGE}:latest"
                    sh "docker cp temp_container:/usr/share/nginx/html ./website-content"
                    sh "docker rm temp_container"

                    // Deploy extracted files to S3
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh "aws s3 sync ./website-content s3://${env.TF_STATE_BUCKET} --delete"
                        echo "Application deployed successfully!"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed!'
        }
        success {
            echo 'Deployment to S3 was successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
