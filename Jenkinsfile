pipeline {
    agent any

    environment {
        DOCKER_USERNAME = 'sashafefler' // Docker Hub username
        DOCKER_PASSWORD = credentials('DH-token') // Docker Hub token stored in Jenkins credentials
        VERSION_FILE = 'version.txt'
        EC2_HOST_TEST = '44.201.139.101' // TEST ec2's public ip
        EC2_HOST_PROD = '54.242.104.130' // PROD ec2's public ip
    }

    stages {
            //             WAS FOR DEBUG             //
        // stage('Ensure Docker Access') {
        //     steps {
        //         echo 'Ensuring Docker access...'
        //         sh '''
        //             if ! docker info > /dev/null 2>&1; then
        //                 echo "Docker daemon not accessible. Ensure the Jenkins user is in the Docker group."
        //                 exit 1
        //             else
        //                 echo "Docker is accessible."
        //             fi
        //         '''
        //     }
        // }

        stage('Setup Versioning') {
            steps {
                echo 'Setting up versioning...'
                sh '''
                    if [ ! -f "$WORKSPACE/$VERSION_FILE" ]; then
                        echo "0.1" > "$WORKSPACE/$VERSION_FILE"
                        echo "$VERSION_FILE" >> .gitignore
                        echo "Initialized versioning at 0.0"
                    fi
                '''
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up before cloning...'
                sh '''
                    if [ -d "devops1114-spacecapybara" ]; then
                        echo "Directory exists, cleaning up..."
                        rm -rf devops1114-spacecapybara
                    else
                        echo "Directory does not exist, no cleanup needed."
                    fi
                '''
            }
        }
        
        stage('Clone') {
            steps {
                echo 'Cloning git repo...'
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh 'git clone https://$GITHUB_TOKEN@github.com/AlexandraFefler/devops1114-spacecapybara.git'
                }
            }
        }


        // fuck this for now, it all keeps looping and I just want it to work first
        // stage('Increment Version') {
        //     steps {
        //         echo 'Incrementing version...'
        //         withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
        //             sh '''
        //                 # Ensure we use the correct GitHub credentials
        //                 git remote set-url origin https://$GITHUB_TOKEN@github.com/AlexandraFefler/devops1114-spacecapybara.git

        //                 # Ensure we are on the main branch
        //                 git checkout main || git checkout -b main

        //                 # Pull latest changes to avoid merge conflicts
        //                 git pull origin main --rebase

        //                 # Read current version
        //                 CURRENT_VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
        //                 NEW_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{print $1 "." $2+1}')
        //                 echo "$NEW_VERSION" > "$WORKSPACE/$VERSION_FILE"

        //                 echo "Updated version to $NEW_VERSION"

        //                 # Git setup
        //                 git config --global user.email "sasha.fefler@gmail.com"
        //                 git config --global user.name "AlexandraFefler"

        //                 # Commit and push the version update
        //                 git add "$WORKSPACE/$VERSION_FILE"
        //                 git commit -m "CI: Bump version to $NEW_VERSION [skip ci]"
        //                 git push https://$GITHUB_TOKEN@github.com/AlexandraFefler/devops1114-spacecapybara.git main
        //             '''
        //         }
        //     }
        // }

        stage('Increment Version') {
            steps {
                echo 'Incrementing version...'
                sh '''
                    CURRENT_VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
                    NEW_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{print $1 "." $2+1}')
                    echo "$NEW_VERSION" > "$WORKSPACE/$VERSION_FILE"
                    echo "Updated version to $NEW_VERSION"
                '''
            }
        }

        stage('Docker Login') {
            steps {
                echo 'Logging into Docker Hub...'
                sh '''
                    set -x # Log commands
                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                    docker info | grep Username
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building Docker image using docker-compose with hardcoded .env file...'
                sh '''
                    cd devops1114-spacecapybara

                    # Create the .env file with hardcoded values
                    cat <<EOF > .env
                    FLASK_ENV=development
                    MYSQL_HOST=db
                    MYSQL_USER=user
                    MYSQL_PASSWORD=password
                    MYSQL_DATABASE=mydatabase
                    MYSQL_ROOT_PASSWORD=admin
                    WEB_PORT=5002
                    SQL_PORT=3306
                    VERSION=latest
                    EOF

                    echo FLASK_ENV=development > .env

                    # Export version variable
                    export VERSION=$(cat "$WORKSPACE/$VERSION_FILE")

                    # Build using Docker Compose
                    docker-compose build --no-cache

                    echo "Built Docker image with docker-compose"
                '''
            }
        }

        // stage('Build') {
        //     steps {
        //         echo 'Building Docker image...'
        //         sh '''
        //             cd devops1114-spacecapybara
        //             VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
        //             docker build -t sashafefler/devops1114-spacecapybara:$VERSION .
        //             echo "Built Docker image with tag sashafefler/devops1114-spacecapybara:$VERSION"
        //         '''
        //     }
        // }

            //             WAS FOR DEBUG             //
        // stage('Verify Image') {
        //     steps {
        //         echo 'Verifying built image...'
        //         sh '''
        //             docker images | grep "sashafefler/devops1114-spacecapybara"
        //         '''
        //     }
        // }

    // add tag "latest" in addition to version 
        stage('Push to DH') {
            steps {
                echo 'Pushing the built image to Docker Hub with retry...'
                script {
                    def retries = 3
                    def success = false
                    while (!success && retries > 0) {
                        try {
                            sh '''
                                VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
                                echo "Attempting to push: sashafefler/devops1114-spacecapybara:$VERSION"
                                docker push sashafefler/devops1114-spacecapybara:$VERSION
                            '''
                            success = true
                        } catch (Exception e) {
                            retries--
                            echo "Push failed. Retries left: ${retries}"
                            if (retries == 0) {
                                error "Docker push failed after multiple attempts."
                            }
                        }
                    }
                }
            }
        }

        // stage('Run Container') {
        //     steps {
        //         echo "Ensuring that previous containers don't run, running the Docker container..."
        //         sh '''
        //             VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
        //             docker stop devops1114-spacecapybara || true
        //             docker rm devops1114-spacecapybara || true
        //             docker run -d -p 8000:8000 --name devops1114-spacecapybara sashafefler/devops1114-spacecapybara:$VERSION
        //         '''
        //     }
        // }

        stage('Connect to testing env') {
            steps {

                echo 'Connecting to testing ec2 and running tests... not real rn'
                // withCredentials([sshUserPrivateKey(credentialsId: 'ec2-key-testing', keyFileVariable: 'SSH_KEY')]) {
                //     sh '''
                //         VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
                //         chmod 400 $SSH_KEY
                //         echo "Connecting to EC2 instance..."
                //         ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST_PROD <<EOF
                //         echo "Stopping existing container (if any)..."
                //         docker stop devops1114-spacecapybara || true
                //         docker rm devops1114-spacecapybara || true

                //         echo "Pulling latest Docker image..."
                //         docker pull sashafefler/devops1114-spacecapybara:$VERSION

                //         echo "Running the new container..."
                //         docker run -d -p 8000:8000 --name devops1114-spacecapybara sashafefler/devops1114-spacecapybara:$VERSION

                //         echo "Deployment completed!"EOF
                //     '''
                // }
            }
        }

        stage('Test') {
            steps {
                echo 'Running curl test... not real rn'
                // sh '''
                //     sleep 5
                //     if curl -s -o /dev/null -w "%{http_code}" http://$EC2_HOST_TEST:5002 | grep -q "^200$"; then
                //         echo "Test passed: App is responding with HTTP 200."
                //     else
                //         echo "Test failed: App is not responding with HTTP 200."
                //         exit 1
                //     fi
                // '''
            }
        }

        stage('Push stable version to DH as latest') {
            steps {
                echo 'Pushing the stable image to Docker Hub with retry... not real rn too, should be no latest for now'
                // clear copypaste bruh what this scripting lang even is oops (like still groovy? smth else??)
                // script {
                //     def retries = 3
                //     def success = false
                //     while (!success && retries > 0) {
                //         try {
                //             sh '''
                //                 VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
                //                 echo "Attempting to push: sashafefler/devops1114-spacecapybara:latest"
                //                 docker push sashafefler/devops1114-spacecapybara:latest
                //             '''
                //             success = true
                //         } catch (Exception e) {
                //             retries--
                //             echo "Push failed. Retries left: ${retries}"
                //             if (retries == 0) {
                //                 error "Docker push failed after multiple attempts."
                //             }
                //         }
                //     }
                // }
            }
        }

        // ssh -o StrictHostKeyChecking=no -> automatic 'yes' response to asking to confirm trusting the server we try to connect to 
        // <<EOF commands...EOF executes all the commands inside here in the ssh command (inside the connected machine) so we don't have to use ssh for every command 
        // docker stop devops1114-spacecapybara || true -> try to stop a running container, but if such container doesn't exist and the command fails, then return true anyway cuz we got to the state we wanted which is "no such container running" 
        
        // thanks to pushing only the stable version as latest, deployment can now use latest to fool-proof from deploying unstable versions that haven't passed the tests (you can always see what's the latest version's number is in DH)
        // At second thought this might be a little less useful instead of always seeing the version in the code instead of "latest" for later debug or whatever... hm 
        
        stage('Deploy') {
            steps {
                echo 'Deploying to EC2 instance... not real too'
                // withCredentials([sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'SSH_KEY')]) {
                //     sh '''
                //         VERSION=$(cat "$WORKSPACE/$VERSION_FILE")
                //         chmod 400 $SSH_KEY
                //         echo "Connecting to EC2 instance..."
                //         ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@$EC2_HOST_PROD <<EOF
                //         echo "Stopping existing container (if any)..."
                //         docker stop devops1114-spacecapybara || true
                //         docker rm devops1114-spacecapybara || true

                //         echo "Pulling latest Docker image..."
                //         docker pull sashafefler/devops1114-spacecapybara:$VERSION

                //         echo "Running the new container..."
                //         docker run -d -p 8000:8000 --name devops1114-spacecapybara sashafefler/devops1114-spacecapybara:latest

                //         echo "Deployment completed!"EOF
                //     '''
                // }
            }
        }
    }
}