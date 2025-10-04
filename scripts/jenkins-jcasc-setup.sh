#!/bin/bash
export DEBIAN_FRONTEND=noninteractive


# Install AWS CLI v2
echo "**************************************************************************"
echo "*                                                                        *"
echo "*                           Installing AWS CLI                           *"
echo "*                                                                        *"
echo "**************************************************************************"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update

# Check version
aws --version


echo "**************************************************************************"
echo "*                                                                        *"
echo "*                                                                        *"
echo "*                           Installing Jenkins                           *"
echo "*                                                                        *"
echo "*                                                                        *"
echo "**************************************************************************"

sudo apt-get update
sudo apt-get install fontconfig openjdk-21-jre -y

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

java -version

echo "Starting Jenkins"
sudo systemctl start jenkins || true


echo "Waiting for Jenkins to start..."
MAX_WAIT=120   # seconds
WAITED=0
until curl -sSf http://localhost:8080/login >/dev/null 2>&1; do
  sleep 5
  echo "Waiting... $WAITEDs"
  WAITED=$((WAITED+5))
  if [ $WAITED -ge $MAX_WAIT ]; then
    echo "WARNING: Jenkins did not start within $MAX_WAIT seconds. It may start on first boot."
    break
  fi
done
echo "Jenkins setup step complete (build-time may skip full start)"
echo systemctl status jenkins

echo "Downloading Jenkins CLI"
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

export JENKINS_URL=http://localhost:8080
export JENKINS_USER=admin
export JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Install recommended plugins
plugins=(
  cloudbees-folder
  antisamy-markup-formatter
  build-timeout
  credentials-binding
  timestamper
  ws-cleanup
  ant
  gradle
  workflow-aggregator
  github-branch-source
  pipeline-github-lib
  pipeline-stage-view
  git
  github
  github-api
  ssh-slaves
  matrix-auth
  pam-auth
  ldap
  email-ext
  mailer
  metrics
  pipeline-graph-view
  docker-commons
  configuration-as-code
  job-dsl
  nodejs
  terraform
)

# Install the recommended plugins
echo "Installing recommended plugins"
for plugin in "${plugins[@]}"; do
  echo "Installing plugin: $plugin"
  java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" install-plugin "$plugin"
done

export GH_ACCESS_TOKEN=$(head -n 1 tokens.txt)
export DOCKER_ACCESS_TOKEN=$(tail -n 1 tokens.txt)

# Replace placeholders in the casc.yaml file
echo "Replacing placeholders in the casc.yaml file"
sudo sed -i "s/\${GH_ACCESS_TOKEN}/$GH_ACCESS_TOKEN/g" ~/casc.yaml
sudo sed -i "s/\${DOCKER_ACCESS_TOKEN}/$DOCKER_ACCESS_TOKEN/g" ~/casc.yaml

echo "Copying JCasC configuration"
sudo mv ~/casc.yaml /var/lib/jenkins/casc.yaml
sudo chown jenkins:jenkins /var/lib/jenkins/casc.yaml

echo "Copying Jenkins jobs"
sudo mv ~/*.groovy /var/lib/jenkins/
sudo chown jenkins:jenkins /var/lib/jenkins/*

# Configure JAVA_OPTS to disable setup wizard
sudo mkdir -p /etc/systemd/system/jenkins.service.d/
sudo tee /etc/systemd/system/jenkins.service.d/override.conf >/dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dcasc.jenkins.config=/var/lib/jenkins/casc.yaml"
EOF

echo "Starting Jenkins (non-blocking for AMI build)"
# Attempt to start Jenkins, but do not enable it in Packer builds
sudo systemctl daemon-reload
sudo systemctl stop jenkins || true
sudo systemctl start jenkins || true  # ignore errors if systemd can't fully run

echo "Waiting for Jenkins to start..."
MAX_WAIT=120   # seconds
WAITED=0
until curl -sSf http://localhost:8080/login >/dev/null 2>&1; do
  sleep 5
  echo "Waiting... $WAITEDs"
  WAITED=$((WAITED+5))
  if [ $WAITED -ge $MAX_WAIT ]; then
    echo "WARNING: Jenkins did not start within $MAX_WAIT seconds. It may start on first boot."
    break
  fi
done
echo "Jenkins setup step complete (build-time may skip full start)"


echo "Jenkins setup completed"

# Installing Nodejs
echo "**************************************************************************"
echo "*                                                                        *"
echo "*                                                                        *"
echo "*                           Installing Nodejs                            *"
echo "*                                                                        *"
echo "*                                                                        *"
echo "**************************************************************************"

# Download and import the Nodesource GPG key
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo \
  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Create a deb repository
NODE_MAJOR=22
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo \
  tee /etc/apt/sources.list.d/nodesource.list

# Run update and install
sudo apt-get update && sudo apt-get install -y nodejs

sleep 3

# Check Node version:
echo "Node $(node --version)"

# Add Docker's official GPG key:
echo "**************************************************************************"
echo "*                                                                        *"
echo "*                                                                        *"
echo "*                           Installing Docker                            *"
echo "*                                                                        *"
echo "*                                                                        *"
echo "**************************************************************************"
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Install Docker:
sudo apt-get update && sudo apt-get install -y docker-ce

# Provide relevant permissions
sudo chmod 666 /var/run/docker.sock
sudo usermod -a -G docker jenkins

# Check Docker version
echo "Docker $(docker --version)"

# Install Terraform 
echo "**************************************************************************"
echo "*                                                                        *"
echo "*                                                                        *"
echo "*                           Installing Terraform                           *"
echo "*                                                                        *"
echo "*                                                                        *"
echo "**************************************************************************"

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install -y terraform

# Check Terraform version
terraform -help
