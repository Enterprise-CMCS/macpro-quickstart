jenkins:
  mode: NORMAL
  crumbIssuer: standard
  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Read:anonymous"
        - "Overall/Administer:authenticated"
  securityRealm:
    googleOAuth2:
      clientId: "${jenkins_google_oauth_client_id}"
      clientSecret: "${jenkins_google_oauth_client_secret}"
      domain: "${jenkins_google_oauth_domain}"
  clouds:
    - ecs:
        cluster: "${slave_cluster_arn}"
        credentialsId: none
        jenkinsUrl: "${jenkins_alternative_url}"
        name: "ecs_slaves"
        regionName: "${region}"
        templates:
          - label: "${ec2_jnlp_slave["label"]}"
            assignPublicIp: false
            cpu: 1
            templateName: "na"
            image: "na"
            launchType: "${ec2_jnlp_slave["launch_type"]}"
            memory: 0
            memoryReservation: 0
            networkMode: "default"
            privileged: false
            remoteFSRoot: "/home/jenkins"
            securityGroups: "${task_security_group}"
            sharedMemorySize: 0
            subnets: "${join(",", task_subnets)}"
            taskDefinitionOverride: "${ec2_jnlp_slave["family"]}"
            uniqueRemoteFSRoot: false
          - label: "${fargate_jnlp_slave["label"]}"
            assignPublicIp: false
            cpu: 1
            templateName: "na"
            image: "na"
            launchType: "${fargate_jnlp_slave["launch_type"]}"
            memory: 0
            memoryReservation: 0
            networkMode: "default"
            privileged: false
            remoteFSRoot: "/home/jenkins"
            securityGroups: "${task_security_group}"
            sharedMemorySize: 0
            subnets: "${join(",", task_subnets)}"
            taskDefinitionOverride: "${fargate_jnlp_slave["family"]}"
            uniqueRemoteFSRoot: false
          - label: "${fargate_appian_slave["label"]}"
            assignPublicIp: false
            cpu: 1
            templateName: "na"
            image: "na"
            launchType: "${fargate_appian_slave["launch_type"]}"
            memory: 0
            memoryReservation: 0
            networkMode: "default"
            privileged: false
            remoteFSRoot: "/home/jenkins"
            securityGroups: "${task_security_group}"
            sharedMemorySize: 0
            subnets: "${join(",", task_subnets)}"
            taskDefinitionOverride: "${fargate_appian_slave["family"]}"
            uniqueRemoteFSRoot: false
tool:
  git:
    installations:
      - name: git
        home: /usr/bin/git
security:
  scriptApproval:
    approvedSignatures:
      - method hudson.model.Run getPreviousSuccessfulBuild
      - method hudson.plugins.git.GitSCM getUserRemoteConfigs
      - method hudson.plugins.git.UserRemoteConfig getUrl
      - method javax.xml.transform.Transformer transform javax.xml.transform.Source javax.xml.transform.Result
      - method javax.xml.transform.TransformerFactory newTransformer javax.xml.transform.Source
      - method org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper getRawBuild
      - new javax.xml.transform.stream.StreamResult java.lang.String
      - new javax.xml.transform.stream.StreamSource java.io.Reader
      - new javax.xml.transform.stream.StreamSource java.lang.String
      - staticMethod javax.xml.transform.TransformerFactory newInstance
      - method org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper getRawBuild
unclassified:
  gitscm:
    globalConfigName: jenkins
    globalConfigEmail: jenkins@example.com
    createAccountBasedOnEmail: true
  location:
    adminAddress: admin@example.com
    url: ${jenkins_url}
