salt_master_service:
  service.running:
    - name: salt-master
    - enable: True

salt_directory:
  file.directory: 
    - name: /srv/salt

# Get the list of remote branches
{% set branches = [] %}
{% for origin_branch in salt['git.ls_remote'](remote='git@gitlab.hpc.taltech.ee:hpc/salt/salt-poc.git', opts='--heads', user='root', identity='/root/.ssh/id_rsa') %}
  {% set i = branches.append(origin_branch.replace('refs/heads/', '')) %}
{% endfor %}

# Delete any directories that are no longer remote branches
{% for dir in salt['file.find']('/srv/salt/', type='d', maxdepth=1)
if dir.startswith('/srv/salt/') and dir.split('/')[-1] not in branches and not '/srv/salt/' %}

{{ dir }}:
  file.absent:
    - require_in:
      - file: environment_roots

{% endfor %}

# Clone each branch
{% for branch in branches %}

salt_repo_{{ branch }}:
  git.latest:
    - name: git@gitlab.hpc.taltech.ee:hpc/salt/salt-poc.git
    - target: /srv/salt/{{ branch }}
    - rev: {{ branch }}
    - branch: {{ branch }}
    - user: root
    - identity: /root/.ssh/id_rsa
    - force_checkout: True
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - require:
      - file: salt_directory
    - require_in:
      - file: environment_roots

{% endfor %}

# Render file_roots config to generate environments
environment_roots:
  file.managed:
    - name: /etc/salt/master.d/roots.conf
    - template: jinja
    - source: salt://{{ slspath }}/files/roots.conf.jinja
    - user: root
    - mode: 644
    - listen_in:
      - service: salt_master_service