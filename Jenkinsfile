pipeline {
    agent any


    environment {
     
        IMAGE_TAG = "${BUILD_NUMBER}"
      
    }
    stages {
        stage('Checkout') {
           steps {
                git branch: 'master', url: 'https://github.com/SaRan111997/reactjs-task-ippopay.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    bat '''
                    echo Installing React dependencies...
                    npm install
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    bat '''
                    echo Running tests...
                    npm test -- --passWithNoTests
                    '''
                }
            }
        }

        stage('Build React App') {
            steps {
                script {
                    bat '''
                    echo Building React app...
                    npm run build
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        echo "Building Docker image with tag: %IMAGE_TAG%"
        
                       
        
                        bat """
                        echo Building Docker image...
                        docker build -t %ECR_REPO%:%IMAGE_TAG% .
                        """
        
                        echo "Docker image built successfully: ${ecrRepo}:${imageTag}"
                    }
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    bat '''
                    echo Logging into AWS ECR...
                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.%AWS_REGION%.amazonaws.com

                    echo Tagging Docker image...
                    docker tag %ECR_REPO%:%IMAGE_TAG% <your-aws-account-id>.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%

                    echo Pushing Docker image to ECR...
                    docker push <your-aws-account-id>.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    bat '''
                    echo Deploying to Staging environment...
                    docker run -d -e NODE_ENV=%STAGING_ENV% <your-aws-account-id>.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                    '''
                }
            }
        }

       
    }

    post {
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed. Check the logs for more details."
        }
    }
}
