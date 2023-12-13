# (SCTP) Cloud Infrastructure Engineering Capstone Project 
## Cohort 3 Group 2
## Members: Neo Chih Hao, Zaw Nyein Aung, Sharir, Nasiruddin, Soh Guo Yuen
<br>

## Project 
Project Name: **Wadapdoge**

Repository: https://github.com/Mha47/c3g2-capstone-rev1

Description: Wadapdoge is an instant messaging application based on socket.io. It allows users to log into a chatroom to chat with their friends anywhere in realtime. Users are also able to see the number of other users online within the chat as well as customize their own nicknames prior to logging into the chatroom. 
<br>

## Application Design

Wadapdoge consists of a frontend and backend. 

### Frontend:
The frontend is designed using html, javascript and css. 

### Backend:
Backend consists of code using Node.JS, express framework and the socket.io library. 

The backend is also containerized and deployed via AWS ECS. 

### Architecture:

![Screenshot 2023-12-12 231437](https://github.com/Mha47/chatapp-try/assets/134026955/5ca0e9ff-d964-44a9-a92a-62421eb838c2)

## Branching Strategy

![Screenshot 2023-12-12 234053](https://github.com/Mha47/chatapp-try/assets/134026955/58e09d26-f757-406e-aa0b-c18db7edcfb3)

### Dev branch
https://github.com/Mha47/c3g2-capstone-rev1
- serves as primary integration branch for ongoing development work.
- acts as a staging area for features and bug fixes before they are merged into the main branch.
- Developers regularly merge their completed feature branches into the dev branch for integration testing and collaboration.

### Feature branch
- Created by developers to work on specific features or bug fixes independently. 
- Represents a self-contained task or feature development.
- Once the feature is completed it is merged into the dev branch for further integration. 

### UAT branch
https://github.com/Mha47/c3g2-capstone-rev1/tree/uat
- Serves as the User Acceptance Test staging area.
- More tests are run on the code here before push to Prod.
  
### Prod branch
https://github.com/Mha47/c3g2-capstone-rev1/tree/prod
- Represents the production-ready state of the application.
- It contains stable and thoroughly tested code that is ready to be deployed to the live environment.
- Only fully reviewed and approved code changes are merged from stage into the production branch.
- It is typically protected, meaning that direct commits or modifications are restricted, and changes can only be introduced through pull requests after thorough code review and testing.
  
### Branch rules
The Dev, UAT and Prod branches require a pull request before merging and these branches require at least 1 other developer to review and approve the code before merging. The protection rules are set via github console as shown below:
<br> 

![Screenshot 2023-12-13 213028](https://github.com/Mha47/chatapp-try/assets/134026955/b1e55571-f59c-42cf-9e81-5da37077667d)


## GitHub Actions
We uses GitHub Actions to automate our CI/CD Pipeline. These include building up pipeline structure, the branching strategy, code reviews, test and deployment.

### About Our GitHub Actions Workflows
Our workflows consist of 4 main components, namely the feature, dev, uat and prod. Each components represent the name of the branch we are adopting in this project.
The steps as follows:
- Any changes make has to go through feature branch.
- Upon push to feature, it must run some application test first to ensure the application works.
- In the dev environment, it will then be deployable into the aws.
- user testing will be conducted after dev --> uat environment.
- Once all the test and results are achieve, it will be operational deploy in the prod environment.
- we adopt a manual pull and merge request for every of our branching strategy.

### `feature.yml`
The workflow is triggered on push event to the 'feature' branch.
```
on:
  push:
    branches:
      - 'feature**'
```
Allow access for our workflow. Our workflow make use of OIDC to allow access of github runners to aws.
```
permissions:
  id-token: write # This is required for requesting the JWT.
  actions: read # Permission to read actions.
  contents: read # Permission to read contents.
  security-events: write # Grants permission to write security event data for the repository.
```
Jobs in the feature branch
In `pre-deploy` job, it is echo message on the event name and the reference branch.

In `unit-testing` job, **npm install** , **npm test** command is used to test run the application.  A need function is use  so that the `pre-deploy` job must complete successfully before this job will run.

### `dev.yml`
The additional steps done in the `deploy` job:
- Create an ECR repository using Terraform. Build and push Docker image to the Amazon ECR Repository.
- Use Terraform to create AWS ECS resources, cluster, task definition, and service.
- Condition checks to wait and make sure the ECS task definition, and service are create and running in order to proceed with the next action.
- Display ouput of the url to access the service running.

```
 # This job handles deployment to the development environment
  deploy:
    runs-on: ubuntu-latest
    outputs:
      access_url_output: ${{ steps.tf-outputs.outputs.access_url }} # Define outputs for this job which can be used in subsequent jobs.
    needs: [ pre-deploy, unit-testing, ] # This job depends on the completion of 'pre-deploy', 'unit-testing' jobs
    name: Deploy to AWS
    # Set environment variables for this job. Here, the deployment environment is set based on the branch name 'dev'.
    env:
      environment: ${{ github.ref_name }} # Specify the environment to deploy
    steps:
      
      # Checkout the latest code from the repository
      - name: Checkout repo code
        uses: actions/checkout@v3
      
      # Set up AWS credentials by using OIDC authentication which are stored in the Github Actions Secrets
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.IAM_ROLE}}
          aws-region: us-east-1
      
      # Log in to Amazon ECR (Elastic Container Registry)
      - name: Login to Amazon ECR 
        id: login-ecr # Define an id which allows other steps to reference outputs from this step.
        uses: aws-actions/amazon-ecr-login@v1
        with:
          mask-password: true

      # Create an ECR repository using Terraform and output the repository url for the input to the subsequent steps.
      - name: Create ECR repository using Terraform
        id: terraform-ecr # Define an id which allows other steps to reference outputs from this step.
        working-directory: ./modules/ecr
        run: |
          terraform init
          terraform plan
          terraform apply -auto-approve
          echo "ecr_url=$(terraform output -json | jq -r .repository_url.value)" >> $GITHUB_OUTPUT
      
      # Build and push the Docker image to the Amazon ECR Repository using the repository url from the previous step.
      - name: Push image to Amazon ECR
        id: push-image  # Define an id which allows other steps to reference outputs from this step.
        env:
          image_tag: latest # Define the image tag
        run: |
          docker build -t ${{ steps.terraform-ecr.outputs.ecr_url }}:$image_tag .
          docker push ${{ steps.terraform-ecr.outputs.ecr_url }}:$image_tag

      # Use Terraform to create AWS ECS resources like cluster, task definition, and service
      - name: Create AWS ECS cluster, task definition and service using Terraform
        id: terraform-ecs # Define an id which allows other steps to reference outputs from this step.
        working-directory: ./environments/${{ env.environment }}  # Set the working directory for this step
        # 'terraform apply -auto-approve' command is used to create or update the resources with auto-approval.
        # Variables are passed using the '-var' option to customize the Terraform configuration.
        # The '-target' option is used to restrict the scope of resource application.
        # Mark the ECS service resource for recreation in the next Terraform apply.
        run: |
          terraform init
          terraform apply -auto-approve \
          -var "image_name=${{ steps.terraform-ecr.outputs.ecr_url }}" \
          -target="aws_ecs_cluster.cluster" -target="aws_ecs_task_definition.task" \
          -target="aws_security_group.ecs_sg" -target="aws_ecs_service.service"
          terraform taint aws_ecs_service.service

          # Output the ECS cluster name for use in subsequent steps.
          echo "ecs_name=$(terraform output -json | jq -r .ecs_name.value)" >> $GITHUB_OUTPUT
      
      # Ensure that ECS task is running before proceeding to next step.
      - name: Check if ECS task is running
        run: |
          # Define ECS cluster and service names based on previous Terraform outputs.
          cluster_name=${{ steps.terraform-ecs.outputs.ecs_name}}
          service_name="${{ steps.terraform-ecs.outputs.ecs_name}}-service"
        
          # Set a timeout and interval for checking task status
          timeout=600 # Wait for 10 minutes max
          interval=30 # Check every 30 seconds
        
          # Capture the start time for timeout tracking
          start_time=$(date +%s)
        
          # Begin loop to check task status
          while true; do
              # Calculate elapsed time
              current_time=$(date +%s)
              elapsed_time=$((current_time - start_time))
                       
              # Fetch the task ARNs associated with the service
              task_arns=$(aws ecs list-tasks --cluster $cluster_name --service-name $service_name --query "taskArns" --output text)
                       # If no tasks are found, wait for the interval duration and then check again
              if [ -z "$task_arns" ]; then
                  echo "No tasks found. Waiting..."
                  sleep $interval
                  continue
              fi
        
              # Fetch the last status of the tasks
              statuses=$(aws ecs describe-tasks --cluster $cluster_name --tasks $task_arns --query "tasks[*].lastStatus" --output text)
        
              # Start by assuming all tasks are in the "RUNNING" state.
              all_running=true
        
              # Loop through each status and check if it's "RUNNING"
              for status in $statuses; do
                  if [ "$status" != "RUNNING" ]; then
                      all_running=false
                      break
                  fi
              done
        
              # If all tasks are running, exit the loop
              if $all_running; then
                  echo "All tasks are running."
                  break
              fi
        
              # If timeout is reached before all tasks are running, exit with an error
              if [[ $elapsed_time -ge $timeout ]]; then
                  echo "Timeout reached before all tasks reached RUNNING state."
                  exit 1
              fi
        
              # Wait for the specified interval before checking again
              echo "Waiting for tasks to reach RUNNING state..."
              sleep $interval
          done

      # Retrieve the access URL from Terraform outputs
      - name: Set up Terraform outputs
        id: tf-outputs  # Define an id for this step to be used in the subsequent steps.
        working-directory: ./environments/${{ env.environment }}  # Set the working directory for this step
        # Apply the Terraform configuration with the '-refresh-only' option to only refresh the state without creating/updating any resources.
        # Iinput variables are passed using the '-var' option. These are used to customize the Terraform configuration.
        # Fetch the 'all_access_urls' output from Terraform and process it with 'jq' to retrieve the access URL.
        run: |
          terraform apply -refresh-only -auto-approve -var "image_name=${{ steps.terraform-ecr.outputs.ecr_url }}"
          echo "access_url=$(terraform output -json all_access_urls | jq -r 'to_entries[0].value')" >> $GITHUB_OUTPUT

      # Display the access URL in the GitHub Actions log
      - name: Echo Access URL 
        run: echo "The Access URL is ${{ steps.tf-outputs.outputs.access_url }}"
```

### `uat.yml`
In the uat environment, we added synk scan in our uat, pre-deploy. These are to check for Snyk vulnerabilities and run Snyk code scan.
```
package-osc-scan-snyk-scan:
    runs-on: ubuntu-latest
    needs: unit-testing
    steps:
      - name: Check out repository code
        uses: actions/checkout@v3
      - name: Install Snyk CLI
        run: npm install -g snyk
      - name: Run Snyk to check for vulnerabilities
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

  # We will also use Snyk to perform code scanning of our Terraform IAC files

  package-iac-scan-snyk-scan:
    runs-on: ubuntu-latest
    needs: unit-testing
    steps:
      - name: Check out repository code
        uses: actions/checkout@v3
      - name: Install Snyk CLI
        run: npm install -g snyk
      - name: Run Snyk Code Scan And Check Snyk Scan Results
        uses: snyk/actions/iac@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
```

### `prod.yml`
After all the tests are done in the dev and the uat, prod is deployed using the same method and code displayed in both of the dev and uat branching strategy.


