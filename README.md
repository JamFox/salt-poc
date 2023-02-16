# Salt for configuration management proof of concept

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

Clone this repository and copy `states/` contents to `/srv/salt` (the default base directory for Salt):

```bash
git clone git@gitlab.hpc.taltech.ee:hpc/salt/salt-poc.git /srv/salt/
```

Then enable and start both master and minion:

```bash
sudo systemctl enable salt-master && sudo systemctl start salt-master
sudo systemctl enable salt-minion && sudo systemctl start salt-minion
```

And run `salt 'salt' state.apply salt.refresh_repo`