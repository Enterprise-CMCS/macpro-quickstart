FROM centos:centos7.8.2003

# set working directory
WORKDIR /workdir

# Install unzip utility
RUN yum install -y unzip

# Install git.  Some terraform modules are fetched from git.
RUN yum install -y git

# Install Terraform
RUN curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip \
  && unzip ./terraform_0.12.24_linux_amd64.zip -d /usr/local/bin \
  && rm terraform_0.12.24_linux_amd64.zip

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm awscliv2.zip

# Install Docker
RUN yum install -y yum-utils \
  && yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo \
  && curl -O "https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-19.03.8-3.el7.x86_64.rpm" \
  && yum install -y ./docker-ce-19.03.8-3.el7.x86_64.rpm && \
  rm docker-ce-19.03.8-3.el7.x86_64.rpm
