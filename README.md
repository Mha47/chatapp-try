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
- serves as primary integration branch for ongoing development work.
- acts as a staging area for features and bug fixes before they are merged into the main branch.
- Developers regularly merge their completed feature branches into the dev branch for integration testing and collaboration.

### Feature branch
- Created by developers to work on specific features or bug fixes independently. 
- Represents a self-contained task or feature development.
- Once the feature is completed it is merged into the dev branch for further integration. 

### UAT branch
- Serves as the User Acceptance Test staging area.
- More tests are run on the code here before push to Prod.
  
### Prod branch
- 
## Workflow


