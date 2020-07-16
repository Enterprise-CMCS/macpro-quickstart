jenkins:
  mode: NORMAL
  crumbIssuer: standard
  securityRealm:
    local:
      allowsSignup: false
  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Read:anonymous"
        - "Overall/Administer:authenticated"
  globalNodeProperties:
    - envVars:
        env:
          - key: APPLICATION_BUCKET
            value: ${application_bucket}
          - key: SLAVE_SECURITY_GROUP
            value: ${slave_security_group}
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
      - new java.util.ArrayList
      - new hudson.model.StringParameterValue java.lang.String java.lang.String
      - method org.jenkinsci.plugins.workflow.cps.CpsScript $build
      - method hudson.model.Actionable getAction java.lang.Class
      - method hudson.model.ParametersAction createUpdated java.util.Collection
      - method hudson.model.Actionable addOrReplaceAction hudson.model.Action
credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: GIT_CREDENTIAL
              username: "${git_username_for_jenkins}"
              password: "${git_access_token_for_jenkins}"
jobs:
  - script: >
      multibranchPipelineJob('dev') {
        branchSources {
          git {
            id('1')
            remote('${git_https_clone_url}')
            credentialsId('GIT_CREDENTIAL')
            includes('dev-*')
          }
        }
        configure { project ->
          project / 'triggers' / 'com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger'(plugin: 'cloudbees-folder@6.12') {
            'spec'('* * * * *')
            'interval'('60000')
          }
        }
        factory {
          workflowBranchProjectFactory {
            scriptPath('.jenkins/Jenkinsfile.dev')
          }
        }
      }
  - script: >
      pipelineJob('master') {
        environmentVariables(DOWNSTREAM_JOB: 'preprod', VPC_NAME: 'dev')
        definition {
          cpsScm {
            scm {
              git{
                branch('master')
                remote {
                  url('${git_https_clone_url}')
                  credentials('GIT_CREDENTIAL')
                }
              }
              scriptPath('.jenkins/Jenkinsfile.master')
            }
          }
        }
        configure { project ->
          project / 'properties' / 'org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty' / 'triggers' / 'hudson.triggers.SCMTrigger' {
            'spec'('* * * * *')
          }
        }
      }
  - script: >
      pipelineJob('preprod') {
        parameters {
          stringParam('VERSION', '', 'The version to deploy.  Versions are published by development pipelines and indicate which artifacts to deploy and what git tag to pull.  This should be a tag of format (number).(number).(number)  ex. 0.1.20')
        }
        environmentVariables(DOWNSTREAM_JOB: 'prod', VPC_NAME: 'preprod')
        definition {
          cpsScm {
            scm {
              git{
                branch('\$VERSION')
                remote {
                  url('${git_https_clone_url}')
                  credentials('GIT_CREDENTIAL')
                }
              }
              scriptPath('.jenkins/Jenkinsfile.prod')
            }
          }
        }
      }
  - script: >
      pipelineJob('prod') {
        parameters {
          stringParam('VERSION', '', 'The version to deploy.  Versions are published by development pipelines and indicate which artifacts to deploy and what git tag to pull.  This should be a tag of format (number).(number).(number)  ex. 0.1.20')
        }
        environmentVariables(VPC_NAME: 'prod')
        definition {
          cpsScm {
            scm {
              git{
                branch('\$VERSION')
                remote {
                  url('${git_https_clone_url}')
                  credentials('GIT_CREDENTIAL')
                }
              }
              scriptPath('.jenkins/Jenkinsfile.prod')
            }
          }
        }
      }

unclassified:
  gitscm:
    globalConfigName: jenkins
    globalConfigEmail: jenkins@example.com
    createAccountBasedOnEmail: true
  location:
    adminAddress: admin@example.com
    url: ${jenkins_url}
