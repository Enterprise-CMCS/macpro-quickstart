FROM jenkins/jenkins:lts-centos

# Install docker compose
USER root
RUN curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose
USER jenkins

# Load our plugins onto the image
COPY files/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Load our Configuration as Code (CasC) yml files onto the image
COPY files/casc_configs /var/casc_configs
USER root
RUN chown -R jenkins:jenkins /var/casc_configs
USER jenkins
ENV CASC_JENKINS_CONFIG /var/casc_configs

# Instruct Jenkins not to run the initial setup wizard
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"
