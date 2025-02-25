pipeline {
    agent any

    environment {
        EXTERNAL_STORAGE = "/mnt/Storage"
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

                    // Ensure the storage path exists
                    sh "mkdir -p ${repoPath}"

                    // Clone or update the repo
                    sh """
                    if [ ! -d ${repoPath}/.git ]; then
                        git clone ${repoUrl} ${repoPath}
                    else
                        cd ${repoPath} && git pull
                    fi
                    """

                    // Count the number of commits (edit/update number)
                    def buildNumber = sh(script: "cd ${repoPath} && git rev-list --count HEAD || echo 0", returnStdout: true).trim()

                    // Store environment variables
                    env.REPO_PATH = repoPath
                    env.REPO_OWNER = repoOwner
                    env.REPO_NAME = repoName
                    env.BUILD_NUMBER = buildNumber
                    env.IMAGE_TAG = "${repoOwner}_${repoName}:v${buildNumber}"

                    echo "✅ Repository cloned/updated at ${repoPath}"
                    echo "📌 Build Number: ${buildNumber}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Ensure Dockerfile exists
                    sh """
                    if [ ! -f ${env.REPO_PATH}/Dockerfile ]; then
                        echo "❌ No Dockerfile found in ${env.REPO_PATH}. Skipping build."
                        exit 1
                    fi
                    """

                    // Build Docker image
                    sh """
                    cd ${env.REPO_PATH}
                    docker build -t ${env.IMAGE_TAG} .
                    """

                    echo "✅ Docker image ${env.IMAGE_TAG} built successfully!"
                }
            }
        }

        stage('Stop Old Container') {
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
            steps {
                script {
                    def containerPort = 8000 + (env.BUILD_NUMBER as Integer)
                    env.CONTAINER_PORT = containerPort

                    sh """
                    docker run -d --name ${env.REPO_OWNER}_${env.REPO_NAME} -p ${env.CONTAINER_PORT}:8000 ${env.IMAGE_TAG}
                    """

                    echo "🚀 Running container on port ${env.CONTAINER_PORT}"
                }
            }
        }

        stage('Clean Up Old Images') {
            steps {
                script {
                    sh "docker image prune -f"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed. Check logs."
        }
    }
}

