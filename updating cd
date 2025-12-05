// pipeline {
//     agent any

//     environment {
//         // Your Kali IP + Port 5000
//         REGISTRY = "100.93.190.2:5000" 
//         IMAGE_NAME = "juice-shop"
//         IMAGE = "${REGISTRY}/${IMAGE_NAME}"
//         // Generates a tag like "build-1", "build-2"
//         TAG = "build-${BUILD_NUMBER}" 
        
//         // Connect to SonarQube
//         scannerHome = tool 'SonarQubeScanner'
//     }

//     stages {
//         stage('Checkout') {
//             steps {
//                 // Pulls code from your repo
//                 checkout scm
//             }
//         }

//         stage('SAST - SonarQube Analysis') {
//             steps {
//                 withSonarQubeEnv('sonar-server') {
//                     sh "${scannerHome}/bin/sonar-scanner"
//                 }
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 script {
//                     sh "docker build -t ${IMAGE}:${TAG} ."
//                 }
//             }
//         }

//         stage('Push to Registry') {
//             steps {
//                 script {
//                     sh "docker push ${IMAGE}:${TAG}"
//                 }
//             }
//         }
//     }
// }



pipeline {
    agent any

    environment {
        // YOUR KALI IP HERE
        REGISTRY = "100.93.190.2:5000"
        IMAGE_NAME = "juice-shop"
        IMAGE = "${REGISTRY}/${IMAGE_NAME}"
        TAG = "build-${BUILD_NUMBER}"
        
        // YOUR UBUNTU IP HERE (Juice Shop runs on NodePort 30080)
        TARGET_URL = "http://100.77.83.125:30080"

        scannerHome = tool 'SonarQubeScanner'
    }

    stages {
        stage('Checkout') {
            steps {
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

        stage('Container Security - Trivy') {
            steps {
                sh "trivy image --exit-code 0 --severity HIGH,CRITICAL --no-progress ${IMAGE}:${TAG}"
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    sh "docker push ${IMAGE}:${TAG}"
                }
            }
        }

        /* ---------------------- NEW DEPLOYMENT STAGE ---------------------- */

        stage('Deploy to Production') {
            steps {
                script {
                    echo "Deploying to Ubuntu Minikube Cluster..."

                    // 1. Pull new image on Ubuntu host
                    sh "ssh -o StrictHostKeyChecking=no thekernelghost@100.77.83.125 'docker pull ${IMAGE}:${TAG}'"

                    // 2. Load into Minikube internal cache
                    sh "ssh -o StrictHostKeyChecking=no thekernelghost@100.77.83.125 'minikube image load ${IMAGE}:${TAG}'"

                    // 3. Update deployment image
                    sh "ssh -o StrictHostKeyChecking=no thekernelghost@100.77.83.125 'kubectl set image deployment/juice-shop juice-shop=${IMAGE}:${TAG}'"

                    // 4. Wait for rollout
                    sleep 20
                }
            }
        }

        /* ---------------------- DAST STAGE ---------------------- */

        stage('DAST - OWASP ZAP Scan') {
            steps {
                script {
                    echo "Starting ZAP Scan against ${TARGET_URL}"
                    sh "bash ci/zap.sh ${TARGET_URL}"
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
        }
    }
}
