#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "**************************************************************************"
echo "*                           Installing System Packages                   *"
echo "**************************************************************************"

# Single update & install core packages
sudo apt-get update
sudo apt-get install -y unzip curl gnupg software-properties-common fontconfig openjdk-21-jre ca-certificates wget

# ---------------------------
# Install AWS CLI v2 (no /tmp)
# ---------------------------
echo "**************************************************************************"
echo "*                           Installing AWS CLI                           *"
echo "**************************************************************************"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
aws --version

# ---------------------------
# Install Jenkins
# ---------------------------
echo "**************************************************************************"
echo "*                           Installing Jenkins                           *"
echo "**************************************************************************"
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins
java -version
sudo systemctl start jenkins || true

echo "Waiting briefly for Jenkins to initialize..."
sleep 10

# ---------------------------
# Download Jenkins CLI
# ---------------------------
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar
export JENKINS_URL=http://localhost:8080
export JENKINS_USER=admin
export JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# ---------------------------
# Install Plugins
# ---------------------------
plugins=(
  cloudbees-folder antisamy-markup-formatter build-timeout credentials-binding timestamper ws-cleanup
  ant gradle workflow-aggregator github-branch-source pipeline-github-lib pipeline-stage-view
  git github github-api ssh-slaves matrix-auth pam-auth ldap email-ext mailer metrics
  pipeline-graph-view docker-commons configuration-as-code job-dsl nodejs terraform
)

echo "Installing recommended plugins..."
for plugin in "${plugins[@]}"; do
  echo "Installing plugin: $plugin"
  java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" install-plugin "$plugin"
done

# ---------------------------
# Replace placeholders in JCasC file
# ---------------------------
export GH_ACCESS_TOKEN=$(head -n 1 tokens.txt)
export DOCKER_ACCESS_TOKEN=$(tail -n 1 tokens.txt)

sudo sed -i "s/\${GH_ACCESS_TOKEN}/$GH_ACCESS_TOKEN/g" ~/casc.yaml
sudo sed -i "s/\${DOCKER_ACCESS_TOKEN}/$DOCKER_ACCESS_TOKEN/g" ~/casc.yaml
sudo mv ~/casc.yaml /var/lib/jenkins/casc.yaml
sudo chown jenkins:jenkins /var/lib/jenkins/casc.yaml

# ---------------------------
# Copy Jenkins Jobs
# ---------------------------
sudo mv ~/*.groovy /var/lib/jenkins/
sudo chown jenkins:jenkins /var/lib/jenkins/*

# ---------------------------
# Disable Setup Wizard via systemd override
# ---------------------------
sudo mkdir -p /etc/systemd/system/jenkins.service.d/
sudo tee /etc/systemd/system/jenkins.service.d/override.conf >/dev/null <<EOF
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false -Dcasc.jenkins.config=/var/lib/jenkins/casc.yaml"
EOF

sudo systemctl daemon-reload
sudo systemctl stop jenkins || true
sudo systemctl start jenkins || true

# ---------------------------
# Install Node.js
# ---------------------------
echo "**************************************************************************"
echo "*                           Installing Nodejs                             *"
echo "**************************************************************************"
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install -y nodejs
echo "Node $(node --version)"

# ---------------------------
# Install Docker
# ---------------------------
echo "**************************************************************************"
echo "*                           Installing Docker                             *"
echo "**************************************************************************"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce
sudo chmod 666 /var/run/docker.sock
sudo usermod -a -G docker jenkins
echo "Docker $(docker --version)"

# ---------------------------
# Install Terraform
# ---------------------------
echo "**************************************************************************"
echo "*                           Installing Terraform                          *"
echo "**************************************************************************"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform
terraform -help

echo "**************************************************************************"
echo "*                           Jenkins AMI setup complete                     *"
echo "**************************************************************************"
