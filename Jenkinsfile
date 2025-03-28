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
                    git credentialsId: 'github-token', url: 'https://github.com/SefaliSabnam/DEPLOYMENT.git', branch: env.BRANCH_NAME
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
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh 'terraform apply -auto-approve tfplan'

                        // Fetch the created S3 bucket name
                        env.S3_BUCKET = sh(script: "terraform output -raw bucket_name", returnStdout: true).trim()
                        echo "S3 Bucket: ${env.S3_BUCKET}"
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
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    // Create container and extract files
                    sh "docker create --name temp_container ${DOCKER_IMAGE}:latest"
                    sh "docker cp temp_container:/usr/share/nginx/html ./website-content"
                    sh "docker rm temp_container"

                    // Deploy extracted files to S3
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh "aws s3 sync ./website-content s3://${env.S3_BUCKET} --delete"
                        echo "Application deployed: http://${env.S3_BUCKET}.s3-website.ap-south-1.amazonaws.com"
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
