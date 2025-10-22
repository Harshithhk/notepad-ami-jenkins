# Notepad AMI Jenkins

Project to setup and deploy Jenkins using Packer and GitHub Actions.

## Overview

This project automates the creation of an AWS AMI (Amazon Machine Image) with Jenkins pre-installed and configured. It uses HashiCorp Packer for building the AMI and GitHub Actions for CI/CD automation.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured locally
- Packer installed (version 1.7.0 or higher)
- GitHub account (for GitHub Actions)
- Basic knowledge of AWS EC2 and Jenkins

## Project Structure

```
notepad-ami-jenkins/
├── .github/
│   └── workflows/          # GitHub Actions workflows
├── packer/
│   ├── jenkins.pkr.hcl    # Packer template for Jenkins AMI
│   └── scripts/           # Provisioning scripts
├── README.md
└── .gitignore
```

## Features

- Automated AMI creation using Packer
- Jenkins pre-installed and configured
- CI/CD pipeline with GitHub Actions
- Secure and repeatable infrastructure as code
- Easy deployment to AWS

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Harshithhk/notepad-ami-jenkins.git
cd notepad-ami-jenkins
```

### 2. Configure AWS Credentials

Set up your AWS credentials as GitHub Secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 3. Packer Configuration

Update the Packer template with your specific requirements:

```bash
cd packer
packer validate jenkins.pkr.hcl
```

### 4. Build AMI Locally (Optional)

To build the AMI locally:

```bash
packer build jenkins.pkr.hcl
```

## GitHub Actions Workflow

The project includes automated workflows that:

1. Validate Packer templates on pull requests
2. Build and publish AMI on merge to main branch
3. Tag releases with AMI ID

### Triggering a Build

Push to the main branch or create a new release to trigger the AMI build process.

## AMI Details

The created AMI includes:

- **Operating System**: Amazon Linux 2 / Ubuntu (specify your base)
- **Jenkins**: Latest LTS version
- **Java**: OpenJDK 11 or 17
- **Additional Tools**: Git, Docker, AWS CLI

## Deployment

### Launching an EC2 Instance from the AMI

1. Navigate to AWS EC2 Console
2. Click "Launch Instance"
3. Select "My AMIs" and choose your Jenkins AMI
4. Configure instance settings
5. Add security group (ensure port 8080 is open)
6. Launch the instance

### Accessing Jenkins

1. Get the public IP of your EC2 instance
2. Access Jenkins at: `http://<your-instance-ip>:8080`
3. Retrieve the initial admin password:

```bash
ssh -i your-key.pem ec2-user@<your-instance-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Security Considerations

- Always use secure credentials management
- Restrict security group access to known IP addresses
- Regularly update Jenkins and plugins
- Enable HTTPS for production deployments
- Use IAM roles instead of hardcoded credentials

## Customization

### Modifying Jenkins Configuration

Edit the provisioning scripts in `packer/scripts/` to customize:

- Jenkins plugins
- System configurations
- User permissions
- Build tools

### Environment Variables

Configure environment-specific variables in your Packer template:

```hcl
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}
```

## Troubleshooting

### Packer Build Fails

- Verify AWS credentials are correctly configured
- Check IAM permissions for EC2, VPC, and AMI operations
- Review Packer logs for specific errors

### Jenkins Not Accessible

- Verify security group allows inbound traffic on port 8080
- Check if Jenkins service is running: `sudo systemctl status jenkins`
- Review Jenkins logs: `sudo journalctl -u jenkins`

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- HashiCorp Packer documentation
- Jenkins community
- AWS documentation

## Contact

For questions or support, please open an issue in the GitHub repository.

---

**Author**: Harshithhk  
**Repository**: [github.com/Harshithhk/notepad-ami-jenkins](https://github.com/Harshithhk/notepad-ami-jenkins)