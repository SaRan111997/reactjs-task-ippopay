pipeline {
    agent any

    environment {
        AWS_REGION = "${env.AWS_REGION}"
        ECR_REPO = "${env.ECR_REPO}"
        IMAGE_TAG = "${env.BUILD_ID}"
        AWS_ACCOUNT_ID = "${env.AWS_ACCOUNT_ID}"
    }

    stages {
        stage('Load Environment Variables') {
            steps {
                script {
                    def envFile = readFile('.env').trim()
                    envFile.split('\n').each { line ->
                        def (key, value) = line.tokenize('=')
                        env[key.trim()] = value.trim()
                    }
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git branch: 'master', url: 'https://github.com/SaRan111997/reactjs-task-ippopay.git'
            }
        }

        stage('AWS Configuration') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials', region: '${AWS_REGION}')]) {
                    sh 'aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID'
                    sh 'aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY'
                    sh 'aws configure set region ${AWS_REGION}'
                }
            }
        }

        stage('Test') {
            steps {
                sh 'docker run --rm -v $(pwd):/app -w /app node:20 sh -c "npm ci && npm run test"'
            }
        }

        stage('Build') {
            steps {
                sh 'docker run --rm -v $(pwd):/app -w /app node:20 sh -c "npm run build"'
                archiveArtifacts artifacts: 'build/**', fingerprint: true
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'docker run --rm -v $(pwd):/app -w /app node:20 sh -c "npm install"'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    sh 'docker build -t ${ECR_REPO}:${IMAGE_TAG} .'
                    sh 'docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}'
                    sh 'docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest'
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}'
                    sh 'docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest'
                }
            }
        }

        stage('Deploy to Staging') {
            environment {
                REACT_APP_ENV = 'staging'
            }
            steps {
                sh "docker run -e REACT_APP_ENV=${REACT_APP_ENV} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to Production') {
            environment {
                REACT_APP_ENV = 'production'
            }
            steps {
                sh "docker run -e REACT_APP_ENV=${REACT_APP_ENV} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
            }
        }
    }
}
