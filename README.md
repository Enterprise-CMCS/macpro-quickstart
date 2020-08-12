# quickstart-tech-challenge

![Collabralink](https://collabralink.com/wp-content/uploads/logo.png)

Low on time, but in short:  This repo was desinged to get a software project off the ground as quickly as possible; it was initially built as a tech challenge accelerator.

- Locally, the app is built, deployed, and tested in containers orchestrated by docker-compose.
- On push to master, the app is built, scanned, and deployed to Amazon using Terraform.
- On success, each master push will be tagged as a candidate release.
- 'n' number of higher environment, preprod and prod in this quickstart, can be added to run ad hoc or automatically, accepting a single version number (tag from master)
- Dev environments can be built in Amazon by pushing a branch matching the pattern dev-*
- A Jenkins CI installation orchestrates all Amazon builds, and is actually the first thing you should build after forking this.
- The Jenkins system is an ECS master with a slave cluster attached and configured with CasC.  All builds run on ECS slave agents, either EC2 or Fargate.


## Usage

Building the app locally
- Clone this repo.  Let's assume you've cloned it to ~/repo
- cd repo
- sh deploy.sh
You can destroy in much the same way, by running destroy.sh
There's also a deployDev.sh, which launches containers with source code mounted to containers as appropriate for hot reloading and other capabilities.

Running tests locally
- Follow instructions to deploy locally.  The application must be up for a successful test run.
- cd repo
- sh test.sh

Standing up Jenkins to build, deploy, and test your app in Amazon.
- Clone this repo.  Let's assume you've cloned it to ~/repo
- cd repo
- Any way you like, open .jenkins/set.env.sh.tpl
- Read the instructions at the top of the file and throughout, and act accordingly.  It should instruct you to create a copy of set.env.sh.tpl and update values.
- cd .jenkins/infra
- sh deploy.sh
- A lot of stuff will kick off.  At the end, a URL will be printed, along with a username and password.  Navigate to the URL, punch in the user/password, and you should be landed on the Jenkins homepage.browser  
- Once on the home page, you should see the jobs created as part of the bootstrapping process.  The master/preprod/prod jobs you see will begin momentarily.  The dev multibranch pipeline is to deploy dev-* branches when pushed.
- All Jenkins configuration is driven by the [Jenkins Configuration as Code plugin](https://github.com/jenkinsci/configuration-as-code-plugin).  If you're curious about our implementation, you can find our CasC template (pretty buried ) in .jeknins [here](.jenkins/infra/terraform/jenkins/jenkins_image/files/casc/jenkins.yml.tpl)
- Configure Jenkins as you wish.  Jenkins is deployed to ECS with data persistence provided by EBS and [rexray](https://github.com/rexray/rexray).
- Have fun!

## Requirements

Bash - All workflows are wrapped in .sh scripts.  This is by design, to minimize the amount of tooling needed installed, as some devs can't modify their workstations.

Docker - The local application and all tooling runs within Docker.  The bootstrapping of Jenkins also occurs in Docker.

Mac/Linux - Since all workflows are simple shells launching docker containers, it was pretty simple to translate the .sh files to .bat and support Windows.  However, demand for Windows support was low, and there was a particularly painful issue with Docker volumes and the deployDev workflow.  Out of the box Windows support was removed to help focus on the product and our Mac majority.  CentOS has been tested, but all major Linux distributions should work.

AWS Account (optional):  You'll need an AWS account with an admin IAM user if you want to build Jenkins in AWS and deploy your application to the cloud.

## Dependencies

None.

## Examples
None.

## Contributing / To-Do

See current open [issues](https://github.com/cmsgov/quickstart-tech-challenge/issues) or check out the [project board](https://github.com/cmsgov/quickstart-tech-challenge/projects/1)

Please feel free to open new issues for defects or enhancements.

To contribute:
- Fork this repository
- Make changes in your fork
- Open a pull request targetting this repository

Pull requests are being accepted.

## License

[![License](https://img.shields.io/badge/License-CC0--1.0--Universal-blue.svg)](https://creativecommons.org/publicdomain/zero/1.0/legalcode)

See [LICENSE](LICENSE.md) for full details.

```text
As a work of the United States Government, this project is
in the public domain within the United States.

Additionally, we waive copyright and related rights in the
work worldwide through the CC0 1.0 Universal public domain dedication.
```

### Contributors

| [![Mike Dial][dial_avatar]][dial_homepage]<br/>[Mike Dial][dial_homepage] | [![Doug White][white_avatar]][white_homepage]<br/>[Doug White][white_homepage] |
|---|---|

  [dial_homepage]: https://github.com/mdial89f
  [dial_avatar]: https://avatars.githubusercontent.com/mdial89f?size=150
  [white_homepage]: https://github.com/dwhitecl
  [white_avatar]: https://avatars.githubusercontent.com/dwhitecl?size=150

See [contributor graphs](https://github.com/cmsgov/quickstart-tech-challenge/graphs/contributors) for full details.
