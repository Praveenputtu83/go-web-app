cat > Jenkinsfile <<'EOF'
pipeline {
    agent any

    environment {
        REGISTRY_URL    = "192.168.152.134:5000"
        IMAGE_NAME      = "go-web-app"
        IMAGE_TAG       = "build-${BUILD_NUMBER}"

        K8S_NAMESPACE   = "go-web-app"
        DEPLOYMENT_NAME = "go-web-app-deployment"
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Trivy Scan') {
            steps {
                sh """
                trivy image --exit-code 1 --severity HIGH,CRITICAL \
                  ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} || {
                      echo "Trivy discovered vulnerabilities"
                      exit 1
                  }
                """
            }
        }

        stage('Push To Nexus Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh """
                    echo "$NEXUS_PASS" | docker login ${REGISTRY_URL} \
                      -u "$NEXUS_USER" --password-stdin

                    docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}

                    docker logout ${REGISTRY_URL}
                    """
                }
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                sh """
                kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

                kubectl -n ${K8S_NAMESPACE} apply -f k8s/deployment.yaml
                kubectl -n ${K8S_NAMESPACE} apply -f k8s/service.yaml

                kubectl -n ${K8S_NAMESPACE} set image deployment/${DEPLOYMENT_NAME} \
                  go-web-app=${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
EOF
