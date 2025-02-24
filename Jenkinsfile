pipeline {
    agent any

    environment {
        EXTERNAL_STORAGE = "/mnt/Storage/apps"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    def repoUrl = env.GIT_URL
                    def repoOwner = repoUrl.tokenize('/')[-2].replace('.git', '')  // Extract GitHub username
                    def repoName = repoUrl.tokenize('/')[-1].replace('.git', '') // Extract repo name
                    def userPath = "${EXTERNAL_STORAGE}/${repoOwner}"
                    def repoPath = "${userPath}/${repoName}"

                    // Ensure the repository path exists
                    sh "mkdir -p ${repoPath}"

                    // Clone or pull the latest changes
                    sh """
                    if [ ! -d ${repoPath}/.git ]; then
                        git clone ${repoUrl} ${repoPath}
                    else
                        cd ${repoPath} && git pull
                    fi
                    """

                    // Store repo details in environment variables
                    env.REPO_PATH = repoPath
                    env.REPO_OWNER = repoOwner
                    env.REPO_NAME = repoName
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        // Get the build number from Git, default to 0 if it fails
                        def buildNumber = sh(
                            script: "cd ${env.REPO_PATH} && git rev-list --count HEAD || echo 0",
                            returnStdout: true
                        ).trim()
        
                        if (buildNumber == "0") {
                            error("❌ Failed to get build number. Make sure the repository is cloned properly.")
                        }
        
                        def containerPort = 8000 + (buildNumber as Integer)
                        env.CONTAINER_PORT = containerPort
                        env.IMAGE_TAG = "${env.REPO_OWNER}_${env.REPO_NAME}:v${buildNumber}"
        
                        // Log important values
                        echo "📌 Build Number: ${buildNumber}"
                        echo "📌 Image Tag: ${env.IMAGE_TAG}"
                        echo "📌 Container Port: ${env.CONTAINER_PORT}"
        
                        // Check if Dockerfile exists before attempting to build
                        sh """
                        cd ${env.REPO_PATH}
                        if [ ! -f Dockerfile ]; then
                            echo "❌ No Dockerfile found in ${env.REPO_PATH}. Skipping build."
                            exit 1
                        fi
                        """
        
                        // Build the Docker image
                        sh """
                        cd ${env.REPO_PATH} &&
                        docker build -t ${env.IMAGE_TAG} .
                        """
        
                        echo "✅ Docker image ${env.IMAGE_TAG} built successfully!"
        
                    } catch (Exception e) {
                        echo "🔥 Error: ${e.message}"
                        error("❌ Build Docker Image stage failed.")
                    }
                }
            }
        }

        stage('Stop Old Container') {
            when {
                expression { env.IMAGE_TAG && env.IMAGE_TAG.trim() != '' }
            }
            steps {
                script {
                    sh """
                    docker stop ${env.REPO_OWNER}_${env.REPO_NAME} || true
                    docker rm ${env.REPO_OWNER}_${env.REPO_NAME} || true
                    """
                }
            }
        }

        stage('Run New Container') {
            when {
                expression { env.IMAGE_TAG && env.IMAGE_TAG.trim() != '' }
            }
            steps {
                script {
                    sh """
                    docker run -d --name ${env.REPO_OWNER}_${env.REPO_NAME} -p ${env.CONTAINER_PORT}:8000 ${env.IMAGE_TAG}
                    """
                }
            }
        }

        stage('Clean Up Old Images') {
            when {
                expression { env.IMAGE_TAG && env.IMAGE_TAG.trim() != '' }
            }
            steps {
                script {
                    sh "docker image prune -f"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! Container running on port ${env.CONTAINER_PORT}"
        }
        failure {
            echo "❌ Deployment failed. Check logs."
        }
    }
}
