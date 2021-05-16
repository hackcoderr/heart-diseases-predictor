# heart-diseases-predictor

## Creating playbook for configuring kubernetes cluster:
Before creating playbooks we have create roles to manage the code properly. So, here i am creating three roles i.e master, slaves and jenkins configuration. you can create roles via below commands:
```
ansible-galaxy init master     # master role
ansible-galaxy init slaves     # slave role
ansible-galaxy init jenkins    # jenkins role
```
<p align="center">
    <img width="900" height="300" src="https://miro.medium.com/max/792/1*XgS3ik7RdhcH6Vvb4R5vBg.jpeg">
</p>

Now create a directory eg. `/myinventory` in Ansible controller node. and you need use dynamic inventory plugins. using `wget` command download the `ec2.py` and `ec2.ini` plugins inside `/myinventory` folder.
```
This 👇 command will create a ec2.py dynamic inventory file 
wget   https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/ec2.py
This 👇 command will create a ec2.ini dynamic inventory file
wget   https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/ec2.ini
You need to make executable those two above files
chmod  +x ec2.py 
chmod  +x ec2.ini
```
<p align="center">
    <img width="900" height="400" src="https://miro.medium.com/max/792/1*-WsGvmv5mIO__cM6seL5mA.jpeg">
</p>

```
You need to give below inputs inside ec2.ini file.
aws_region='ap-south-1' 
aws_access_key=XXXX
aws_secret_access_key=XXXX          

After that export all these commands so boto can use this commands freely.
export AWS_REGION='ap-south-1'
export AWS_ACCESS_KEY_ID=XXXX
export AWS_ACCESS_SECRET_KEY=XXXX

Now we have to edit inside ec2.py file. This file written in python 2 but we are using python 3 so we need to edit the header.

#!/usr/bin/python3
```

![ec.ini](https://miro.medium.com/max/792/1*uUZTGYviA7sEfaOBqMzD-g.jpeg)

![ec2.ini](https://miro.medium.com/max/792/1*TpPvv-HGO2oawgUQahhXKg.jpeg)

Updating `ec2.py` file from python to python3.

![ec2.py](updating ec2.py file from python to python3..)

Install `boto` and `boto3` libraries so ansible can connect to aws services and launch the respective services. To install `boto` and `boto3` using below command.

```
pip3 install boto           # installing boto
pip3 install boto3          # installing boto3
```

<p align="center">
    <img width="900" height="400" src="https://miro.medium.com/max/792/1*fqM8DO2PImcqZ5LRd_VXaw.jpeg">
</p>
Now we can create configuration file of ansible. Your ansible.cdf file must include below configuration codes.

```
[defaults]
inventory= /my_inventory
host_key_checking=false
ask_pass=false
remote_user=ubuntu
private_key_file=/root/mykey.pem
command_warnings=False
[privilege_escalation]
become=True
become_method=sudo
become_user=root
become_ask_pass=False
```
Note: Here, we have given `remote_user=ubuntu` because the master and slaves of the kuberenetes cluster is launched via ubuntu image. The main reson to use ubuntu image is due to we are using crio as a intermediate `container runtime engine`. Only ubuntu supports the repo for `crio` installation. Therefore we are using `ubuntu image`.

Now this `ansible.cfg` file will helps us to configure instances on AWS dynamically. `inventory=/myinventory` (it includes ec2.ini and ec2.py) files. `private_key_file` should be the key in `.pem` format of the instances. `host_key_checking=false` will allow to give proper ssh connection. `privilege_escalation` should be concluded in the ansible.cfg file to configure the system using `sudo` power. Your `ansible.cfg` file will look like this below snip.
<p align="center">
    <img width="900" height="400" src="https://miro.medium.com/max/792/1*fqM8DO2PImcqZ5LRd_VXaw.jpeg">
</p>
Now we are ready to go and configure instanes on aws. use `ansible all --list-hosts` to check the dynamic inventory is working or not.
<p align="center">
    <img width="900" height="200" src="https://miro.medium.com/max/792/1*A9nxto6shUV3WWm9BRYJRA.jpeg">
</p>
If you see the ip’s then your instanes are running on aws and it ansible dynamic inventory is successfully connect to aws.

# Configuring Crio repository:
Now first we have to configure Master node and then slave nodes. To configure crio in ubuntu i have created a script from below codes and saved into `crio.sh` and save in a `/root/` directory.
```
OS=xUbuntu_20.04
VERSION=1.20cat >>/etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list<<EOF
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOFcat >>/etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list<<EOF
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOFcurl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -
```
<p align="center">
    <img width="900" height="400" src="https://miro.medium.com/max/792/1*tZ9xk5Um7RLUElqwAjLzzg.jpeg">
</p>
Now to configure master you need to go inside `master/tasks/main.yml` file to create tasks for configuration.

# Configuring master node:

```
# First we have to copy the crio.sh cript to master node and run it to configure crio in master.

- name: "Copying Script to K8S Master Node"
  copy:
     src: "/root/crio.sh"
     dest: "/root/"
# Running crio.sh script
- name: "running script"
  shell: "bash /root/crio.sh"
  register: crioscript
- debug:
    var: crioscript.stdout_lines# updating packages
- name: "Updating apt"
  shell: "apt update"
  ignore_errors: yes
  register: yumupdate
- debug:
    var: yumupdate.stdout_lines# installing crio
- name: "Instlling CRIO"
  shell: "apt install -qq -y cri-o cri-o-runc cri-tools"
  ignore_errors: yes
  register: crioinstall
- debug:
   var: crioinstall.stdout_lines# reloading daemon
- name: "Reloading System and CRIO"
  shell: "systemctl daemon-reload"# enabling and starting crio 
- name: "enabling CRIO"
  shell: "systemctl enable --now crio"
  ignore_errors: yes
  register: criostart
- debug:
   var: criostart.stdout_lines# Configuring repo for Kubeadm Installing Kubeadm 
- name: "Installing KubeAdm"
  shell: |
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
   apt install -qq -y kubeadm=1.20.5-00 kubelet=1.20.5-00 kubectl=1.20.5-00
  ignore_errors: yes
  register: kubeadminstall
- debug:
   var: kubeadminstall.stdout_lines# Creating a overlay network
- name: "Adding Overlay Network"
  shell: |
   cat >>/etc/modules-load.d/crio.conf<<EOF
   overlay
   br_netfilter
   EOF
  ignore_errors: yes
  register: overlay# adding filters to overlay network 
- name: "Creating Overlay and Netfilter"
  shell: "modprobe overlay"
- shell: "modprobe br_netfilter"
  ignore_errors: yes# enabling iptables by changing values to 1
- name: "Chnaging Iptables values to 1"
  shell: |
   cat >>/etc/sysctl.d/kubernetes.conf<<EOF
   net.bridge.bridge-nf-call-ip6tables = 1
   net.bridge.bridge-nf-call-iptables  = 1
   net.ipv4.ip_forward                 = 1
   EOF
  ignore_errors: yes# running sysctl --system
- name: "Running sysctl --system"
  shell: "sysctl --system"
  register: sysctl
- debug:
     var: sysctl.stdout_lines# changing cgroup drivers to pod
- name: "Chnaging group drivers"
  shell: |
   cat >>/etc/crio/crio.conf.d/02-cgroup-manager.conf<<EOF
   [crio.runtime]
   conmon_cgroup = "pod"
   cgroup_manager = "cgroupfs"
   EOF# reloading daemon
- name: "Reloading System and CRIO"
  shell: "systemctl daemon-reload"
  ignore_errors: yes# enabling crio
- name: "enabling crio"
  shell: "systemctl enable --now crio"
  ignore_errors: yes# restarting crio
- name: "Restarting CRIO"
  shell: "systemctl restart crio"
  ignore_errors: yes# changing fstab and disabling firewall
- name: "Changing Fstab and disable ufw"
  shell: |
     sed -i '/swap/d' /etc/fstab
     swapoff -a
     systemctl disable --now ufw
  ignore_errors: yes# Restarting kubelet
- name: "restarting kubelet"
  shell: "systemctl restart kubelet"# initializing master node with cidr 192.168.0.0/16
- name: "Initilaizing Master"
  shell: "kubeadm init --apiserver-advertise-address=192.168.1.86  --pod-network-cidr=192.168.0.0/16    --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem"
  ignore_errors: yes
  register: master
- debug:
   var: master.stdout_lines- name: "Creating .kube directory"
  shell: "mkdir -p $HOME/.kube"- name: "Copying /etc/kubernetes/admin.conf $HOME/.kube/config"
  shell: "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"- name: "changing owner permission"
  shell: "sudo chown $(id -u):$(id -g) $HOME/.kube/config"# creating calico overlay network to create a connection between the master and slave nodes
- name: "Using Calico as Overlay Network"
  shell: "kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml"
  ignore_errors: yes
  register: callico
- debug:
    var: callico.stdout_lines# generating token
- name: "Printing token"
  shell: "kubeadm token create --print-join-command"
  register: token- debug:
    var: token.stdout_lines
```

# Configuring slave nodes:
```
# First we have to copy the crio.sh cript to master node and run it to configure crio in slaves.
- name: "Copying Script to K8S Master Node"
  copy:
     src: "/root/crio.sh"
     dest: "/root/"# running crio.sh script
- name: "running script"
  shell: "bash /root/crio.sh"
  register: crioscript
- debug:
    var: crioscript.stdout_lines# updating packages
- name: "Updating apt"
  shell: "apt update"
  ignore_errors: yes
  register: yumupdate
- debug:
    var: yumupdate.stdout_lines# Installing Crio
- name: "Instlling CRIO"
  shell: "apt install -qq -y cri-o cri-o-runc cri-tools"
  ignore_errors: yes
  register: crioinstall- debug:
   var: crioinstall.stdout_lines# Reloading Deamon
- name: "Reloading System and CRIO"
  shell: "systemctl daemon-reload"# enabling crio
- name: "enabling CRIO"
  shell: "systemctl enable --now crio"
  ignore_errors: yes
  register: criostart
- debug:
   var: criostart.stdout_lines# installing and configuring repo for kubeadm
- name: "Installing KubeAdm"
  shell: |
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
   apt install -qq -y kubeadm=1.20.5-00 kubelet=1.20.5-00 kubectl=1.20.5-00
  ignore_errors: yes
  register: kubeadminstall
- debug:
   var: kubeadminstall.stdout_lines# creating overlay network
- name: "Adding Overlay Network"
  shell: |
   cat >>/etc/modules-load.d/crio.conf<<EOF
   overlay
   br_netfilter
   EOF
  ignore_errors: yes
  register: overlay# adding filters to overlay network
- name: "Creating Overlay and Netfilter"
  shell: "modprobe overlay"
- shell: "modprobe br_netfilter"
  ignore_errors: yes# enabling iptables by changing values to 1
- name: "Chnaging Iptables values to 1"
  shell: |
   cat >>/etc/sysctl.d/kubernetes.conf<<EOF
   net.bridge.bridge-nf-call-ip6tables = 1
   net.bridge.bridge-nf-call-iptables  = 1
   net.ipv4.ip_forward                 = 1
   EOF
  ignore_errors: yes# running sysctl --system
- name: "Running sysctl --system"
  shell: "sysctl --system"
  register: sysctl
- debug:
     var: sysctl.stdout_lines# changing cgroup drivers to pod
- name: "Changing group drivers"
  shell: |
   cat >>/etc/crio/crio.conf.d/02-cgroup-manager.conf<<EOF
   [crio.runtime]
   conmon_cgroup = "pod"
   cgroup_manager = "cgroupfs"
   EOF# pulling images using kubeadm
- name: "Pulling Images using KubeAdm"
  shell: "kubeadm config  images pull"
  changed_when: false
  register: kubeadm
- debug:
    var: kubeadm.stdout_lines# reloading daemon
- name: "Reloading System and CRIO"
  shell: "systemctl daemon-reload"
  ignore_errors: yes# enabling crio
- name: "enabling crio"
  shell: "systemctl enable --now crio"
  ignore_errors: yes# restarting crio
- name: "Restarting CRIO"
  shell: "systemctl restart crio"
  ignore_errors: yes# changing fstab and disabling firewall
- name: "Changing Fstab and disable ufw"
  shell: |
     sed -i '/swap/d' /etc/fstab
     swapoff -a
     systemctl disable --now ufw
  ignore_errors: yes# Restarting kubelet
- name: "restarting kubelet"
  shell: "systemctl restart kubelet"# Joining Slaves with token
- name: "Joining Slaves to Master Node"
  shell: "{{ master_token  }}"
  ignore_errors: yes
  register: init
- debug:
    var: init.stdout_lines  
```
# Configuring Jenkins Node::
```
---
# tasks file for jenkins# copying jdk file in jenkins node 
- name: "Copying Jdk file to jenkins Node"
  copy:
    src: "/root/jdk-8u281-linux-x64.rpm"
    dest: "/root/"
  ignore_errors: yes# copying jenkins file to jenkins node
- name: "Copying Jenkins file to jenkins Node"
  copy:
    src: "/root/jenkins-2.282-1.1.noarch.rpm"
    dest: "/root/"
  ignore_errors: yes# Installing JDK
- name: "Installing JDK"
  shell: "rpm -ivh /root/jdk-8u281-linux-x64.rpm"
  ignore_errors: yes
  register: jdk
- debug:
     var: jdk.stdout_lines# Installing Jenkins
- name: "Installing Jenkins"
  shell: "rpm -ivh /root/jenkins-2.282-1.1.noarch.rpm"
  ignore_errors: yes
  register: jenkins
- debug:
     var: jenkins.stdout_lines# Staring jenkins
- name: "Starting Jenkins Server"
  shell: "systemctl start jenkins"# enabling jenkins
- name: "enabling Jenkins Server"
  shell: "systemctl enable jenkins"
```
Now the `mainplaybook` will contains the roles of `master`, `slaves` and `jenkins` respectively.

# Main Playbook:
```
# Configuring master node
- hosts: ["tag_Name_K8S_Master_Node"]
  roles:
  - name: "Configuring Master Node"
    role:  "/root/roles/master"# Configuring slaves node
- hosts: ["tag_Name_K8S_Slave1_Node", "tag_Name_K8S_Slave2_Node"]
  vars_prompt:
  - name: "master_token"
    prompt: "Enter Token To Join To Master: "
    private: no
  roles:
  - name: "Configuring Slave Node"
    role:  "/root/roles/slaves"# Configuring jenkins node
- hosts: ["tag_Name_JenkinsNode"]
  remote_user: "ec2-user"
  roles:
  - role: "/root/roles/jenkins"
```
# Running Main Playbook:

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/3.gif">
</p>

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/4.gif">
</p>

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/5.gif">
</p>

You can run the `mainplaybook.yml` using `ansible-playbook mainplaybook.yml`



Now login to jenkins jenkins node using `public_ip:8080`. We need to set the password for jenkins node intially. This process needed to be done only once. You will be landed on this page and it will ask for password.

<p align="center">
    <img width="900" height="300" src="https://miro.medium.com/max/792/1*nYJPAJAXfkeOKUvNuzRUCQ.jpeg">
</p>

copy the `/var/lib/jenkins/secrets/initialAdminPassword` the location and using cat command you can take the passowrd like this in the below image.

![jenkinspass](https://miro.medium.com/max/792/1*uSivwOLfi4z8Nm4016lH4A.jpeg)

Now copy the password and pate in the `Administrator password` section and then click on `continue`.



After that you need to create a password because this password is too long and hard to remember. So below are the steps shown in the video to create the password and to install the restive plugins. Ensure that you have to install below plugins. watch this video for reference https://youtu.be/1spUYaUKaao

Plugins from below lists needed to be installed:

   1. `ssh`: ssh plugins need to install for connecting the kubernetes servers.
   2. `Gihub`: Github plugins need to install to us *SCM services*.
   3. `Pipeline`: Pipline plugin will helps you to automate the jobs and make your setup easy.
   4. `Multibranch pipeline`: Multibranch pipeline plugin will helps you to pulls the code from different branches. In this project i have created two branch i.e main(default) and developer branch. The code should be in both the branch in `Jenkinsfile` named file. So multibranch will scan the repository and both the branches and will pull the code and create jobs with names “*main*” job and “*developer*” job. If developer branch job run successfully then and if main branch wants to commit then they can.

Now you have to create a repository in github and add the pipeline code in that repo inside `Jenkinsfile`.




```
pipeline {     
    agent any      
       stages { 
         stage('BuildingHeartPrectionPod'){   
           steps {                   
           sh 'sudo kubectl create deployment mlopsheartpred  --image=hackcoderr/heart-diseases-predictor:v1   --kubeconfig /root/admin.conf'
           sh 'sudo kubectl expose deployment mlopsheartpred --type=NodePort  --port=4444   --kubeconfig /root/admin.conf'                          
           sh 'sudo kubectl get pod -o wide   --kubeconfig /root/admin.conf'                                
    }       
 }         
       stage('gettingpod'){   
           steps {                     
              sh 'sudo kubectl get pod -o wide  --kubeconfig /root/admin.conf'                  
              sh 'sudo kubectl get svc    --kubeconfig /root/admin.conf'           
          } 
       }   
 }
}
```


Now we need to copy the url of repository and you have to create a new job with `multibranch pipeline` and you need to to add source “git” and paste the url and save the job.

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/8.gif">
</p>
Now you have to just and it will create two `jobs` one for `main branch` and another for `developer branch`. As soon as the developer branch succeed it will create a deployment in the `Kubernetes cluster` and behind the scene it will launch pod and it also expose that `deployment` so any client can access the page.

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/9.gif">
</p>

Now you can access the webapp with the public ip of the slave node and with the exposed port.

<p align="center">
    <img width="900" height="400" src="https://raw.githubusercontent.com/amit17133129/Heart_Diseases_Prediction_App_Creation_Using_MLOps_Tools/main/Images/10.gif">
</p>
