pipeline {
    agent any

    environment {
        // Your Kali IP + Port 5000
        REGISTRY = "100.93.190.2:5000" 
        IMAGE_NAME = "juice-shop"
        IMAGE = "${REGISTRY}/${IMAGE_NAME}"
        // Generates a tag like "build-1", "build-2"
        TAG = "build-${BUILD_NUMBER}" 
        
        // Connect to SonarQube
        scannerHome = tool 'SonarQubeScanner'
    }

    stages {
        stage('Checkout') {
            steps {
                // Pulls code from your repo
                checkout scm
            }
        }

        stage('SAST - SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh "${scannerHome}/bin/sonar-scanner"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE}:${TAG} ."
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    sh "docker push ${IMAGE}:${TAG}"
                }
            }
        }
    }
}