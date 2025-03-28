pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sefali26/banking-app"
        AWS_CREDENTIALS = 'AWS-DOCKER-CREDENTIALS'
        DOCKER_HUB_CREDENTIALS = 'DOCKER_HUB_TOKEN'
    }    

    stages {
        stage('Checkout') {
            steps {
                script {
                    git credentialsId: 'github-token', url: 'https://github.com/SefaliSabnam/Banking-App-Deployment-Statefile.git', branch: env.BRANCH_NAME
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        def initStatus = sh(script: 'yes | terraform init -migrate-state', returnStatus: true)
                        if (initStatus != 0) {
                            echo "Backend configuration changed. Running terraform init -reconfigure..."
                            sh 'terraform init -reconfigure'
                        }
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
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed!'
        }
        success {
            echo 'Deployment was successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
