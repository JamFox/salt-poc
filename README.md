# Salt for configuration management proof of concept

- [Salt In 10 Minutes Walkthrough](https://docs.saltproject.io/en/master/topics/tutorials/walkthrough.html)
- [Salt User Guide](https://docs.saltproject.io/salt/user-guide/en/latest/)
- [Salt Documentation](https://docs.saltproject.io/en/latest/contents.html)

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

## Scheduling jobs

https://docs.saltproject.io/en/latest/topics/jobs/index.html#scheduling-jobs

## File namespaces

https://docs.saltproject.io/en/latest/topics/tutorials/states_pt1.html#install-the-package

## Environments

https://docs.saltproject.io/en/latest/ref/states/top.html

## SLS template variables

https://docs.saltproject.io/en/latest/ref/states/vars.html

## Directory structure

https://docs.saltproject.io/en/latest/topics/best_practices.html#structuring-states-and-formulas

## Best practices

https://docs.saltproject.io/en/latest/topics/best_practices.html

https://youtu.be/RbXnXZu_4ng