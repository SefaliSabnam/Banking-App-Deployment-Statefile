pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "sefali26/banking-app"
        AWS_CREDENTIALS = 'AWS-DOCKER-CREDENTIALS'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    git credentialsId: 'github-token', url: 'https://github.com/SefaliSabnam/DEPLOYMENT.git', branch: env.BRANCH_NAME
                }
            }
        }

        stage('Debug Workspace') {
            steps {
                script {
                    sh 'pwd'
                    sh 'ls -la'
                    sh 'ls -la terraform || true'  // Check if terraform directory exists
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh '''
                            terraform init -backend-config="bucket=sefali-terraform-state-1234" \
                                           -backend-config="key=terraform.tfstate" \
                                           -backend-config="region=ap-south-1"
                        '''
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

                        // Fetch dynamically created S3 bucket name
                        env.S3_BUCKET = sh(script: "terraform output -raw bucket_name", returnStdout: true).trim()
                        echo "S3 Bucket: ${env.S3_BUCKET}"
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'DOCKER_HUB_TOKEN') {
                        sh "docker build -t ${DOCKER_IMAGE} ."
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Application Deployment to S3') {
            when {
                expression { env.BRANCH_NAME == 'main' }
            }
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS, region: 'ap-south-1') {
                        sh """
                            aws s3 cp index.html s3://${env.S3_BUCKET}/index.html
                        """
                        echo "Application successfully deployed to: http://${env.S3_BUCKET}.s3-website.ap-south-1.amazonaws.com"
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
