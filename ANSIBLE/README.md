# Ansible GCP environment preparation
1. Prerequisites are installed `ansible, requests, google-auth, gcloud-cli packages`
2. Create SA on selected GCP project with following permissions `Compute OS Admin Login, Editor, Service Account user`
3. Set up GCP SA with SSH keys
    - login with GCP admin user

       `> gcloud init`
    - Enable OS Login for project
   
      `> gcloud compute project-info add-metadata –metadata enable-oslogin=TRUE`

    - Login with SA user using the json file
   
      `> gcloud auth activate-service-account --key-file=${PATH_TO_SA_KEY}`

    - Generate SSH key for OS login for SA
   
      `> cd ~/.ssh;  ssh-keygen -f ssh-key-ansible-sa`

    - Adding public ssh key to service account
   
      `> gcloud compute os-login ssh-keys add –key-file=ssh-key-ansible-sa.pub`

4. Ansible playbook contains of `main.yml` importing two resources `rabbitNode.yml` and `gcp-firewall.yml` setting up GCP VM and GCP Firewall respectively. RabbitMQ Node is deployed on VM via two roles configuring docker and docker compose and deploying and configuring RabbitMQ together with queues creation.
5. Run `ansible-playbook` with param `-u sa_${SA_UID}` SA_UID can be found in google cloud console in SA detail.

   `ansible-playbook main.yml -u sa_113675051069048240838`