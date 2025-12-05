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
        
        // YOUR UBUNTU IP HERE (Port 30080 is where Juice Shop runs)
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
                // Scans the image we just built.
                // --exit-code 0 means "Don't stop the pipeline even if vulns found" (Good for first run)
                // --severity HIGH,CRITICAL means only show me the big stuff.
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

        /* Skipping Automated Deploy for now to keep your manual setup safe.
           The ZAP scan below will attack the ALREADY RUNNING app on Ubuntu.
        */

        stage('DAST - OWASP ZAP Scan') {
            steps {
                script {
                    echo "Starting ZAP Scan against ${TARGET_URL}"
                    // Runs the script we made in Step 5.1
                    sh "bash ci/zap.sh ${TARGET_URL}"
                }
            }
        }
    }

    post {
        always {
            // This saves the ZAP report so you can see it in Jenkins
            archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
        }
    }
}