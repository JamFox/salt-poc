# Salt for configuration management proof of concept

- [SaltStack overview](https://saidvandeklundert.net/2020-03-20-saltstack-overview/)
- [Ansible User's Guide to Saltstack](https://docs.jamfox.dev/content/devops/saltstack-for-ansible/)
- [Salt In 10 Minutes Walkthrough](https://docs.saltproject.io/en/master/topics/tutorials/walkthrough.html)
- [Salt User Guide](https://docs.saltproject.io/salt/user-guide/en/latest/)
- [Salt Documentation](https://docs.saltproject.io/en/latest/contents.html)

## Directory structure

```
config/                         # Configuration files
    master.conf                 # Master configuration
pillar/                         # Pillar data                      
    top.sls                     # Pillar top file
    salt/                       # Salt variables
        common.sls              # Common variables
        master.sls              # Master variables          
        minion.sls              # Minion variables
states/                         # Salt state formulas
    top.sls                     # Formula top file
    salt/                       # Formulas for configuring Salt
        init.sls                # Init formula          
        master.sls              # Master formula
        minion.sls              # Minion formula
        defaults.yaml           # Default variables
        files/                  # Files for formula
            roots.conf.jinja       # Jinja template for roots.conf
```

- `config/` contains configuration files for the Salt master and minion that need to be copied manually.
- `config/master.conf` contains the [Salt master configuration](https://docs.saltproject.io/en/latest/ref/configuration/master.html).
- `pillar/` contains [pillar data](https://docs.saltproject.io/en/latest/topics/tutorials/pillar.html) AKA the variables.
- `pillar/top.sls` contains the [pillar top file](https://docs.saltproject.io/en/latest/topics/pillar/index.html#declaring-the-master-pillar) that defines which pillar data is applied to which minions. The top file is not used as a location to declare variables and their values, it is used as a way to include other pillar files and organize the way they are matched based on environments or grains.
- `states/` contains [state formulas](https://docs.saltproject.io/en/latest/topics/tutorials/states_pt1.html#states-tutorial) AKA the "playbooks".
- `states/top.sls` contains the [state top file](https://docs.saltproject.io/en/latest/ref/states/top.html) that defines which state formulas are applied to which minions. The top file is not used as a location to declare formulas, it is used to include other state files and organize the way they are matched based on environments or grains.
- Each state formula is a directory under `states/` with an `init.sls` file that contains the state formula. The `init.sls` file is the entry point for the formula. The `init.sls` file can contain other state formulas as dependencies. `files/` contains files and [Jinja templates](https://docs.saltproject.io/en/latest/topics/jinja/index.html) that are used by the formula. `defaults.yaml` contains the [default variables](https://stackoverflow.com/a/34345785) for the formula and is imported in `.sls` files and combined with pillars as needed.

## Setup

### Master setup

By default, the minions assume that the Salt master can be resolved in DNS using the hostname `salt`. Change the DNS records for the Salt master to point `salt.example.com` (replacing `example.com` with your domain) and hostname of the salt master to `salt`: 

```bash
sudo hostnamectl set-hostname salt
```

[To install Salt on CentOS 7](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/centos.html#install-onedir-packages-of-salt-on-centos-7):

Run the following commands to install the Salt Project repository and key:

```bash
sudo rpm --import https://repo.saltproject.io/salt/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
curl -fsSL https://repo.saltproject.io/salt/py3/redhat/7/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo
```

Then do `sudo yum clean expire-cache` to clear the repository metadata.

Install master and minion (because master will also be managed by itself): 

```bash
sudo yum install salt-master
sudo yum install salt-minion
```

Set up the configuration management serivce account SSH keys that can clone Salt repositories under `/root/.ssh/id_rsa` and `/root/.ssh/id_rsa.pub`. 

From this repositories `config` directory copy `master.conf` to `/etc/salt/master.d/`.

Clone this repository to `/srv/salt/master` (the base environment root directory):

```bash
mkdir /srv/salt; git clone git@gitlab.hpc.taltech.ee:hpc/salt/salt-poc.git /srv/salt/master
```

Then enable and start both master and minion:

```bash
sudo systemctl enable salt-master && sudo systemctl start salt-master
sudo systemctl enable salt-minion && sudo systemctl start salt-minion
```

Provided that the hostname is `salt` as described, the minion should automatically try to authenticate with master. Check if there are any unaccepted keys with `salt-key -L`.

Accept the minion key with `salt-key -A` (command to accept all keys).

And run `salt 'salt' state.apply salt.refresh_repo` (rerun on auth error). This will bootstrap the Salt environments per branch.

### Minion setup

[To install Salt on CentOS 7](https://docs.saltproject.io/salt/install-guide/en/latest/topics/install-by-operating-system/centos.html#install-onedir-packages-of-salt-on-centos-7):

Run the following commands to install the Salt Project repository and key:

```bash
sudo rpm --import https://repo.saltproject.io/salt/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
curl -fsSL https://repo.saltproject.io/salt/py3/redhat/7/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo
```

Then do `sudo yum clean expire-cache` to clear the repository metadata.

Install minion: 

```bash
sudo yum install salt-minion
```

Then enable and start minion:

```bash
sudo systemctl enable salt-minion && sudo systemctl start salt-minion
```

By default, the minions assume that the Salt master can be resolved in DNS using the hostname `salt`. If this is so, the only thing needed is to accept the minion authentication key on master with `salt-key -A` (command to accept all keys).


## Version controlling Salt

It is possible to use [`gitfs`](https://docs.saltproject.io/en/latest/topics/tutorials/gitfs.html) alongside the default `rootfs` to automatically fetch Salt formulas, pillars etc from remote git repos, however `gitfs` is unfortunately [buggy](https://github.com/saltstack/salt/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+gitfs) and full of python version mismatch errors (Check the warnings in the [`gitfs` documentation](https://docs.saltproject.io/en/latest/topics/tutorials/gitfs.html)). 

Thus it is better to use the `salt.refresh_repo` formula (in `states/salt/refresh_repo.sls`). This state ensures that the salt-master service is running. It pulls the list of branches from git remote and makes sure that that each branch is cloned into a directory under `/srv/salt/`. It also manages a file in `/etc/salt/master.d/roots.conf` which defines an environment for each branch and restarts the `salt-master` process when the file changes. This uses one repository for both states and pillars, so states are in the `states/` directory and pillars are in the `pillar/` directory.

The `salt.refresh_repo` formula is run on [schedule](https://docs.saltproject.io/en/latest/topics/jobs/index.html#scheduling-jobs) defined in the `master.conf`: 

```yaml
schedule:
  pull_latest_git:
    function: salt.refresh_repo
    cron: '* * * * *'
```

It is also possible to pull the latest on commit using the steps defined in [this blog post](https://clinta.github.io/salt-git-nogitfs/).

## [Best practices](https://docs.saltproject.io/en/latest/topics/best_practices.html), procedures and style guide

1. Modularity and clarity should be emphasized whenever possible.
2. Create clear relations between pillars and states.
3. Use variables when it makes sense but don't overuse them.
4. Store sensitive data in pillar.
5. Don't use grains for matching in your pillar top file for any sensitive pillars.

Keep directory structure shallow and flat. Total depth should 3 levels. The `files/` directory (example: `states/<state name>/files/`) should be the deepest.

When referencing state formulas, keep in mind the [SLS File Namespace](https://docs.saltproject.io/en/latest/topics/tutorials/states_pt1.html#install-the-package). 

Separate state formulas into separate files and include them in the main `init.sls` file.

Use `snake_case` for file names.

Non-SLS files should be in `files/` directory. Including `jinja` templates which should be suffixed with `.jinja`.

"Unhide" dot files with the prefix `dot_`. For example, `.bashrc` should be named `dot_bashrc`.

Comment Salt-managed files with `# Managed by Salt, do not edit manually!` at the top.

Pillars should contain as little as possible to reduce rendering load on the master, but what should definitely be kept in pillars is very specific variables like sensitive/secret data. 

Define default variables in `defaults.yaml` and override them in pillars as a last resort.

Use [grains](https://docs.saltproject.io/en/latest/topics/grains/) and [custom grains on minion configuration](https://docs.saltproject.io/en/latest/topics/grains/#grains-in-the-minion-config) to match minions to states and handle variables in `defaults.yaml`.

Use [SLS template variables](https://docs.saltproject.io/en/latest/ref/states/vars.html).

Don't Repeat Yourself (keep it DRY). Write formulas to be generic and reusable. Use [includes](https://docs.saltproject.io/en/latest/ref/states/include.html) and [extends](https://docs.saltproject.io/en/latest/ref/states/extend.html) to override and avoid repetition.

Avoid cascading style, separate each task into its own section with its own [declaration ID](https://docs.saltproject.io/en/latest/ref/states/highstate.html#id-declaration).

Use [name declarations](https://docs.saltproject.io/en/latest/ref/states/highstate.html#name-declaration) to avoid clashing ID declarations.

Separate logic from states to maintain readability. Avoid inline conditionals, instead use conditionals outside state definitions and use variables to pass the result to the state definition.

Jinja is not a programming language: move complex queries into custom pillars/grains and complex logic/control into Python [execution modules](https://docs.saltproject.io/en/latest/ref/modules/index.html).

Default [render pipe](https://docs.saltproject.io/en/latest/ref/renderers/index.html) is `#!jinja|yaml`. To use Python you can add `python` to the pipe, for example `#!py|jinja|yaml`.

[Environments are defined in the state top file](https://docs.saltproject.io/en/latest/ref/states/top.html).

Schedule jobs with [schedules](https://docs.saltproject.io/en/latest/topics/jobs/index.html#scheduling-jobs).
