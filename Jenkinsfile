pipeline {
  agent any

  environment {
    AWS_REGION = 'us-east-1'
    ECR_REPO   = '615299732970.dkr.ecr.us-east-1.amazonaws.com/cart/shopping-cart'
    CHART_NAME = 'shopping-cart'
    GIT_BRANCH = ''          // Will be set dynamically
    IMAGE_TAG  = ''          // Will be set from Git commit hash
    NAMESPACE  = ''          // Will be set based on GIT_BRANCH
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          GIT_BRANCH = env.BRANCH_NAME ?: 'main'
          git url: 'https://github.com/shehuj/cicd_deploy_eks.git', branch: GIT_BRANCH
        }
      }
    }

    stage('Build & Test') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Build & Push Docker Image to ECR') {
      steps {
        script {
          IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          NAMESPACE = (GIT_BRANCH == 'main') ? 'prod' : 'staging'

          // Export them so they're accessible in the shell
          env.IMAGE_TAG = IMAGE_TAG
          env.NAMESPACE = NAMESPACE

          sh """
            echo "Logging in to ECR..."
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

            echo "Building Docker image..."
            docker build -t $ECR_REPO:$IMAGE_TAG .

            echo "Pushing image to ECR..."
            docker push $ECR_REPO:$IMAGE_TAG
          """
        }
      }
    }

    stage('Helm Deploy to EKS') {
      steps {
        script {
          sh """
            echo "Updating kubeconfig..."
            aws eks update-kubeconfig --region $AWS_REGION --name shopping-cart-cluster

            echo "Preparing Helm chart..."
            helm repo add stable https://charts.helm.sh/stable || true
            helm repo update

            echo "Creating namespace if not exists..."
            kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE
            kubectl config set-context --current --namespace=$NAMESPACE

            echo "Linting Helm chart..."
            helm dependency update helm/$CHART_NAME
            helm lint helm/$CHART_NAME

            echo "Rendering template (optional check)..."
            helm template $CHART_NAME helm/$CHART_NAME \
              --namespace $NAMESPACE \
              --set image.repository=$ECR_REPO \
              --set image.tag=$IMAGE_TAG > helm/$CHART_NAME/templates/deployment.yaml

            echo "Deploying to EKS with Helm..."
            helm upgrade --install $CHART_NAME helm/$CHART_NAME \
              --namespace $NAMESPACE --create-namespace \
              --set image.repository=$ECR_REPO \
              --set image.tag=$IMAGE_TAG
          """
        }
      }
    }
  }

  post {
    success {
      echo "Deployment to ${env.NAMESPACE} successful!"
    }
    failure {
      echo "Pipeline failed on branch ${env.BRANCH_NAME}."
    }
  }
}
