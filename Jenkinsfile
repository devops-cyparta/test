pipeline {
    agent{
        label 'master'
    }
    stages {
        stage('pull src code') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/marwansss/flask_dockerApp.git'
            }
        }
        
        stage('build docker image'){
            steps{
                sh "docker build -t maro4299311/flask_app:$BUILD_NUMBER ."
                withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
    sh "docker login -u $USER -p $PASS"
    sh "docker push maro4299311/flask_app:$BUILD_NUMBER"
}
            }
        }
        
        stage('test'){
            steps{
                echo "no test cases found"
            }
        }
        
        stage('deploy'){
            steps{
                sh "docker run -d -p 500$BUILD_NUMBER:8008 maro4299311/flask_app:$BUILD_NUMBER"
            }
        }
    }
}
