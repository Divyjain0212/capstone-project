pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-south-1'
        TF_VARS_FILE = 'environment/prod/terraform.tfvars'
        ANSIBLE_DIR  = 'ansible'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['deploy', 'destroy'],
            description: 'Select Terraform action'
        )
        string(
            name: 'APP_VERSION',
            defaultValue: 'main',
            description: 'Git branch or tag to deploy'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Target environment'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.GIT_BRANCH} | Environment: ${params.ENVIRONMENT}"
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh """
                        terraform init \
                            -backend-config=environment/${params.ENVIRONMENT}/backend.hcl \
                            -reconfigure
                    """
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh """
                        terraform plan \
                            -var-file=environment/${params.ENVIRONMENT}/terraform.tfvars \
                            -out=tfplan
                    """
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Ansible Deploy') {
            when {
                expression { params.ACTION == 'deploy' }
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    ),
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials'
                    ]
                ]) {
                    sh """
                        cd ${ANSIBLE_DIR}
                        ansible-playbook playbook.yaml \
                            -i inventory.ini \
                            --private-key=${SSH_KEY} \
                            -e "app_version=${params.APP_VERSION}" \
                            -e "env=${params.ENVIRONMENT}"
                    """
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                input message: 'Are you sure you want to DESTROY the infrastructure?'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh """
                        terraform destroy \
                            -var-file=environment/${params.ENVIRONMENT}/terraform.tfvars \
                            -auto-approve
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully for ${params.ENVIRONMENT}!"
        }
        failure {
            echo "Pipeline FAILED for ${params.ENVIRONMENT}! Check logs above."
        }
        always {
            cleanWs()
        }
    }
}
