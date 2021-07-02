# Common-CI
Common-CI project contains a guideline for creation of continuous integration scripts and describes a general approach to continuous integration within 51Degrees. This readme should provide a comprehensive overview of rules and conventions to be expected from existing jobs and which should be followed when new jobs are created.

# Table of content
- [Common-CI](#common-ci)
- [Table of content](#table-of-content)
- [Reasoning](#reasoning)
- [Continuous integration](#continuous-integration)
  - [Approach](#approach)
    - [Overview](#overview)
    - [Build and test](#build-and-test)
    - [Create packages](#create-packages)
  - [Naming convention](#naming-convention)
    - [Azure DevOps Pipelines](#azure-devops-pipelines)
  - [Development guideline](#development-guideline)
    - [Microsoft Azure DevOps Pipelines](#microsoft-azure-devops-pipelines)
    - [YML file](#yml-file)
    - [Build and test platforms](#build-and-test-platforms)
    - [Testing principles](#testing-principles)
    - [Additional documentation](#additional-documentation)
    - [APIs common templates](#apis-common-templates)
- [Continuous deployment](#continuous-deployment)
  - [Configuration](#configuration)
    - [Internal package managers](#internal-package-managers)
  - [Release process](#release-process)
    - [Packages release](#packages-release)
    - [External package managers and public repositories](#external-package-managers-and-public-repositories)
  - [Automation](#automation)
  - [Naming convention](#naming-convention-1)
    - [Azure DevOps Pipelines](#azure-devops-pipelines-1)
- [License](#license)

# Reasoning
In order to keep high hygiene of development work and have clear indication of successful build, test and package creation, a common set of rules should be followed to measure the quality in a consistent manner across all of the projects. The main reason for having continuous integration in 51Degrees is to assure the best possible quality of software products by confirming successful execution of unit, functional, regression and example tests whenever change to the code base is made. Apart from the code related test, other measures prove the quality of software development through verification of successful execution of build and test processes on all supported platforms and architectures. 

 The reason for this document is to describe the technical solutions used for continuous integration in 51Degrees as well as provide a clear guidance on common rules across: 
- Naming conventions;
- Compulsory elements of CI scripts;
- Platforms and environments;
- Requirements for additional documentation;

# Continuous integration
## Approach
### Overview 
This section describes the general approach to continuous integration in 51Degrees. 

As an internal repository management system 51Degrees is using the Azure DevOps services and continuous integration is achieved through Azure DevOps Pipelines. Each pipeline is defined by a single or multiple `yml` scripts. High maintainability of continuous integration is achieved by keeping the tasks shared between the jobs in separate `yml` scripts and reuse them when possible to avoid code duplications and “copy & paste” errors.

51Degrees is using continuous software development practices described in principle as [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).

At least two main continuous integration jobs should be provided for each software project/repository:
- “[Build and test](#build-and-test)”, and
- “[Create packages](#create-packages)”

Binaries built by continuous integration should be configured to perform a release built by default. If debug build configuration is required, additional, explicit jobs should be created to clearly indicate that pipeline output will be in debug mode.

### Build and test
Build and test job should be used for general purpose building and testing process, and should be the initial step of “Build, test and publish”. Continuous integration should be configured to automatically trigger this type of job whenever pull request is created regardless of the destination branch. Job should be automatically performed whenever any code change is made to the active pull request.

Build and test job provides tasks required for the project to build and run unit and regression tests. This job usually runs a sequence of tasks:
- Configuration<br />
This task (or tasks) configures the environment to meet the build requirements. Task should install all dependencies and platform specific packages required for the build and test processes.
- Code checkout<br />
Task to checkout the source code from the version control system. 51Degrees is using Git repositories hosted on Azure DevOps platform: `git clone` with, where required, submodules initialisation (`git submodule update --init --recursive`) should be used.
- Build<br />
Language and project specific build tool execution. 
- Test (and publish the results)<br />
Language and project specific unit, functional, example, or regression testing execution.

Set of tasks may differ between projects due to a requirement of individual approach for language or platform specific solutions. If an individual solution is in place, it should be documented in the `ci/readme.md` file of the given project.

Job <b>must</b> indicate a <b>fail state</b> if any of the following occurs:
- Configuration step fails on installation of any of the dependencies
- Code checkout step fails regardless of the reason
- Build step fails with error or warning - all warnings should be treated as errors
- Any test fails

If multiple operating system platforms should be supported according to [version support table](https://51degrees.com/documentation/_info__version_support.html) “Build and test” job should either:
- implement support for each operating system in a single `yml` file, or
- implement support for each operating system in a separate `yml` file and create a combining `yml` script.

General guideline for selecting the approach is to keep the `yml` file in a consumable size; if environment configuration, build, test, and any platform specific tasks sums up to more than 4 tasks - create a separate `yml` file. Try to use multi-platform matrix configuration whenever possible, more details can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started-multiplatform?view=azure-devops)

<i>Note: Build and test job should be configured in a separate `yml` file to allow performing the set of tasks defined in this job as a part of "Build, test and publish" job.</i>

### Create packages
Create packages job should be used for creation of packages or tagging the repository and continuous integration system should be configured to automatically execute this job whenever pull request from `release` or `hotfix` branch is merged to `main` branch (as described in  [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).

Create packages job performs any tasks required for creation of packages and/or repository version tag. This job usually runs a sequence of tasks which differ for creating the packages and tagging the repository. <br />

Typical tasks for packages creation:<br />
- Package creation<br />
Language and project specific task generating the packages for given language and/or platform. This task should be documented in project specific `ci/readme.md` file.
- Digital signing<br />
This task should digitally sign the generated binaries or packages to assure a high level of quality and trust for the end user.
- Publish artifacts<br />
Packages or binaries produced by [Build, test and publish](#build,-test-and-publish) job should be published as artifacts of the Azure DevOps Pipeline execution. This task is important to support a smooth release process where the product of this step is used as the final release package.

Typical tasks for creating a repository tag:<br />
- Determine repository version number<br />
This step should determine the version number to be used for repository tagging. 51Degrees is using [GitVersion](https://gitversion.readthedocs.io/en/latest/input/docs/build-server-support/build-server/azure-devops/) Azure DevOps plugin to identify the repository version based on the [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).
- Tag the repository<br />
Perform `git tag` operation on the repository using the version number determined in the previous step and `push` the newly created tag to remote.

Job <b>must</b> indicate a <b>fail state</b> if any of the following occurs:
- Package creation fails
- Digital signature process fails
- Artifacts cannot be found or published

## Naming convention
### Azure DevOps Pipelines
There are two main jobs per pipeline: `build and test`, and `create packages` the common naming convention is as follows:
- For “build and test” job:<br />
`<package-name>-test` where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “build and test” job name should be configured as `pipeline-python-test`.
- For “create packages” job when packages are created:<br /> `<package-name>-create-packages`, where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “build, test and publish” job name should be configured as `pipeline-python-create-packages`.
- For “create packages” job when repository is only tagged:<br />
`<package-name>-tag-repository`, where `<package-name>` represents dash-separated repository name; for example for repository `location-php`, “build, test and publish” job name should be configured as `location-php-tag-repository`.
- For jobs in debug configuration:<br />
`<package-name>-<job>-debug`, where `<package-name>` represents dash-separated repository name, `<job>` represents job suffix selected above; for example for repository `device-detection-dotnet`, “build, test and publish” job in `debug` the name should be configured as `device-detection-dotnet-create-packages-debug`.

## Development guideline
### Microsoft Azure DevOps Pipelines
Detailed documentation and useful information about Azure DevOps pipelines can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops).
### YML file
YAML Ain't Markup Language configuration files are used to configure Azure DevOps continuous integration pipelines and more details about how to use them can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema%2Cparameter-schema).


This guideline obligates the CI developer to add comments to any tasks defined in `yml` files that are not self descriptive and requires more information to understand the implemented process. Follow the general rule that “if in doubt - comment” and always ask for peer review in order to address any concerns or possible misunderstandings. 

Comments in `yml` files are achieved by `#` character prefix, for example:<br />
Visual Studio build task from `pipeline-dotnet` project:
```
- task: VSBuild@1
  displayName: 'Build solutions'
  inputs:
    solution: '$(RestoreBuildProjects)'
    vsVersion: '15.0'
    platform: 'Any CPU'
    configuration: '$(BuildConfiguration)'
    clean: true
```
Although relatively self descriptive, could be extended by comments:
```
# Visual studio build task - VS2017 configuration
- task: VSBuild@1
  displayName: 'Build solutions' # defines name of the task displayed in Azure DevOps
  inputs: # Task specific inputs
    solution: '$(RestoreBuildProjects)' # Location of solution file obtained from RestoreBuildProjects variable set by previous NuGet restore step
    vsVersion: '15.0' # Version of Visual Studio to be used (version 15.0 is VS2017)
    platform: 'Any CPU' # Target platform 
    configuration: '$(BuildConfiguration)' # Build configuration as set by strategy matrix at the top of this file
    clean: true # Should we clean?
```

### Build and test platforms
51Degrees provides information about supported platforms and language/API versions. The full table is available on [51Degrees documentation website](https://51degrees.com/documentation/index.html) on [Information/Version support page](https://51degrees.com/documentation/_info__version_support.html). Azure DevOps Pipelines should be configured to at least mirror the requirements setup by the documentation. If platform architecture is not specified in the support version matrix, it is assumed that both 32 and 64 bit platforms are supported and relevant continuous integration jobs should be provided (please ignore 32bit architecture for the operating systems not supporting x86 platforms). If any changes are applied, support removed or added, either the documentation table or CI configuration must be updated to assure full synchronization between the two.
### Testing principles
Whenever testing environment is set up for a project, continuous integration scripts should be configured to perform full set of tests for:
- All platforms supported by the software project
- All architectures supported by the operating system (Linux 32/64bit; Windows 32/64bit; MacOS 64bit)
- All variants of configuration (e.g. for APIs all performance profiles)
- Both debug and release build configurations
### Additional documentation
This guideline covers high-level overview and basic principles for continuous integration configuration in 51Degrees. Due to the nature of software products supported and provided by the company, different approaches may be required for various types of platforms, languages, APIs and their versions. Therefore, this document should be treated as the guideline and any project specific configuration that alters the information provided by this document should be explained in the `readme.md` file stored under the `ci` folder of the given project. Repository containing this document should be added as a submodule to any project that contains Continuous Integration pipeline configured within 51Degrees Azure DevOps environment. Example directory tree expected in the project:
```
<project_root>
  \ci
    \common-ci
      \readme.md
    \readme.md
    \build-and-test.yml
    \build-and-publish.yml
```
### APIs common templates
When tasks are replicated across APIs, they should be made as templates and kept in the `common-ci` repository. Templates that are shared across languages are kept at the root directory of `common-ci` and templates which are only shared within a language APIs should be kept in its distinct folder, named with the language name. Below is an illustration of the of `common-ci` directory structure:
```
\common-ci
  \readme.md
  \languages-common-template.yml
  ...
  \java
    \java-apis-common-template.yml
    ...
  ...
```

# Continuous deployment
## Configuration
Continuous deployment in 51Degrees is configured to continuously publish packages to the internal package manager feed available in Azure DevOps Artifacts service. Deployment is configured to create and publish the packages internally on a daily basis (overnightly) so that the latest version is available for development purposes. 

All of the packages for daily continuous deployment are created based on the latest version of the `develop` repository branch.
### Internal package managers
51Degrees is using Azure DevOps services for continuous integration and deployment configuration. Azure DevOps provides internal repository managers for the main languages supported by 51Degrees APIs: 
- NuGet
- Maven
- NPM
- PyPi

Deployment to internal package managers is performed daily (overnightly) based on changes applied to `develop` branches of the source code repositories. 

## Release process
### Packages release
Packages release process in 51Degrees is handled through Azure DevOps and the deployment to the public repositories is performed manually using packages generated by [Create packages](#create-packages) continuous integration job. As explained in “[Create packages](#create-packages)” section, process of creating the packages is automatically triggered by completion of pull request to the `main` branch of the repository. Created packages are stored as artifacts in Azure DevOps Artifacts and are used in internal release pipelines in order to upload them to the public package managers/repositories.

API release process steps:
- PR completed to the `main` branch.
- Automatic execution of [build, test and publish](#build,-test-and-publish) job.
- Automatic trigger for release pipeline:
  - Automatic upload to internal package manager
  - Manual deployment to public package manager/repository

### External package managers and public repositories
51Degrees provides APIs for a selection of programming languages and packages are available on the following public package managers:
- [NuGet](https://www.nuget.org/profiles/51Degrees)
- [Maven](https://mvnrepository.com/artifact/com.51degrees)
- [Packagist](https://packagist.org/packages/51degrees/)
- [NPM](https://www.npmjs.com/~51degrees)
- [PyPi](https://pypi.org/search/?q=51degrees) (and [TestPyPi](https://test.pypi.org/search/?q=51degrees))
- Source code on [Github](https://github.com/51Degrees/)

## Automation
Fully automated release process use the following flow:
1. Changes are prepared in `release|hotfix` branches.
2. `Trigger release` job starts.
3. All `leaf submodules` `release|hotfix` branches are merged to `main`.
   1. NOTE: `leaf submodules` are modules which do not have any dependencies.
4. Completion of submodule merging trigger merging of the `release|hotfix` branches of the modules which depend on these submodules.
5. Completion of merging `release|hotfix` branches to `main` will also trigger `deployment` of packages both internally and externally.
6. At the end of the `release` process, packages are available to be collected internally; and `deployment` to external reposition are left to be approved by `release engineer`.

The fully automated release process is controlled by a `release-config.json` file, located in the `common-ci` repository. The automated release process can also be enabled or disabled by a global variable `AutomatedRelease` as part of the Azure Devops variable group `CIAutomation`. To support automating the deployment process, powershell scripts and additional pipelines are required. These scripts are located under `common-ci` repository, and are grouped into modules. The additional pipelines are required per API, but shared templated can be reused from `common-ci`.

Additional pipelines:
- The `submodule trigger` pipeline is required for each API to pick up the package deployment from each of its submodules. Since a module can have multiple submodules, multiple triggers might happen at the same time. Thus, this pipeline should cancel all previous builds and only one at a single time.
  - This must be triggered only by a submodule deployment that happened on the 'main' branch.
  - This pipeline, will then perform update of all submodule references and package dependencies, using the versions specified in the `release-config.json`.
- The `pull request completion` job is required to be done at the end of each `build and test` pipeline.
  - This will check if the current build is triggered by a pull request from `release|hotfix` branch to the `main` branch. If it is and the following conditions have been met, it then proceed to complete the corresponding pull request.
    - The `AutomatedRelease` variable has been enabled.
    - All submodule references and package dependencies have been updated.
    - The pull request has been approved and comments have been left unresolved; or approval is not required.

Fully automated deployment trigger procedure:
1. At the start, `release engineer` will need to update the `release-config.json` to specify all release packages and their target release version. Any additional details should also be specified.
   1. NOTE: There is a `release-config-template.json` available for references.
2. Once the `release-config.json` is ready in one of the `release|hotfix` branch of `common-ci`, either the following should trigger the release process:
   1. Complete the pull request that contains the updated `release-config.json` changes to the `main` branch. This will only work based on the assumption that the `common-ci` is specified as submodule of all release APIs.
   2. Trigger the `trigger-release` pipeline of the `common-ci`.

## Naming convention
### Azure DevOps Pipelines
There are two main jobs per pipeline: `deploy internally`, and `deploy externally`. The common naming convention is as follows:
- For “deploy internally” job:<br />
`<package-name>-deploy-internal` where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “deploy internally” job name should be configured as `pipeline-python-deploy-internal`.
- For “deploy externally” job:<br />
`<package-name>-deploy-external`, where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “deploy externally” job name should be configured as `pipeline-python-create-packages`.
- For “deploy” job there is no internal or external package repository:<br />
`<package-name>-deploy`, where `<package-name>` represents dash-separated repository name; for example for repository `location-php`, “deploy” job name should be configured as `location-php-deploy`. This normally happens when there is no package management for a target language; or the only package management supported for a language is via publishing the source code to a public Git repository.

There are other jobs required to support the automated deployment process: `submodule trigger`, and `pull request completion`. The `pull request completion` is required as part of the `build and test` pipeline. Thus, the only required common naming convention is for `submodule trigger` pipeline.
- For “submodule trigger” job:<br />
`<package-name>-submodule-trigger` where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “submodule trigger” job name should be configured as `pipeline-python-submodule-trigger`.

# License
License information can be found in the `LICENSE` file available in this repository.
