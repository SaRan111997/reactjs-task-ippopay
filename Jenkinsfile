pipeline {
    agent any


    environment {
     
        IMAGE_TAG = "latest"
      
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
        
         stage('SAST: Code Analysis') {
            steps {
                bat '''
                echo Running ESLint for security checks...
                npx eslint src/ --ext .js,.jsx

                echo Running Semgrep for security patterns...
                docker run --rm -v %CD%:/src returntocorp/semgrep scan --config "p/react"
                '''
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
                        docker build --no-cache -t %ECR_REPO%:%IMAGE_TAG% .
                        """
        
                        echo "Docker image built successfully: %ECR_REPO%:%IMAGE_TAG%"
                    }
                }
            }
        }
        
        stage('Trivy Scan') {
            steps {
                script {
                    def reportPath = "trivy-report.txt"
                    
                    // Run Trivy and save output to a file
                    bat """
                    trivy image --scanners vuln,secret --docker-host tcp://localhost:2375 %ECR_REPO%:%IMAGE_TAG% > ${reportPath}
                    """

                    // Archive the report for Jenkins
                    archiveArtifacts artifacts: reportPath, fingerprint: true
                }
            }
        }
        stage('Run React App in Docker') {
    steps {
        bat '''
        echo Removing existing React app container if it exists...
        docker rm -f reactapp || echo No existing container to remove.

        echo Running Docker container for the React app...
        docker run -d -p 3000:80 --name reactapp %ECR_REPO%:%IMAGE_TAG%
        '''
    }
}


        stage('Run OWASP ZAP Scan') {
    steps {
        bat '''
        echo Running OWASP ZAP against the running app...
        docker run --rm -v %CD%:/zap/wrk zaproxy/zap-stable zap-baseline.py -t http://host.docker.internal:3000 -r zap_report.html
        exit 0
        '''
    }
}

stage('Send ZAP Report Email') {
    steps {
        emailext(
            subject: 'OWASP ZAP Security Scan Report - React App',
            body: '''Hello Team,

The OWASP ZAP security scan for the React application has completed. Please find the attached report.

Best regards,
Jenkins Pipeline
''',
            to: 'saran1191997@gmail.com',
            attachmentsPattern: 'zap_report.html',
            mimeType: 'text/html'
        )
    }
}
    
        stage('AWS Configure') {
            steps {
                script {
                    echo "Configuring AWS CLI from environment variables..."
                    bat """
                    aws configure set aws_access_key_id %AWS_ACCESS_KEY_ID%
                    aws configure set aws_secret_access_key %AWS_SECRET_ACCESS_KEY%
                    aws configure set region %AWS_REGION%
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    bat '''
                    echo Logging into AWS ECR...
                    aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

                    echo Tagging Docker image...
                    docker tag %ECR_REPO%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%

                    echo Pushing Docker image to ECR...
                    docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    bat '''
                    echo Deploying to Staging environment...
                    docker run -d -e NODE_ENV=%STAGING_ENV% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
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
    
    always {
            // Send Email with Trivy Report
            emailext(
                subject: "Trivy Scan Report for ippopay/reactapp:latest",
                body: "Hi Team,\n\nPlease find attached the Trivy vulnerability scan report.\n\nRegards,\nJenkins",
                attachLog: false,
                attachmentsPattern: "trivy-report.txt",
                to: 'saran1191997@gmail.com'
            )
        }
    
    }
}
