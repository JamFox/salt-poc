salt-master:
  service.running:
    - enable: True

/srv/salt:
  file.directory: []

# get the list of remote branches
{% set branches = [] %}
{% for origin_branch in salt['git.ls_remote'](remote='git@gitlab.hpc.taltech.ee:hpc/salt/salt-poc.git', opts='--heads', user='root', identity='/root/.ssh/id_rsa') %}
  {% set i = branches.append(origin_branch.replace('refs/heads/', '')) %}
{% endfor %}

# delete any directories that are no longer remote branches
{% for dir in salt['file.find']('/srv/', type='d', maxdepth=1)
if dir.startswith('/srv/salt/') and dir.split('/')[-1] not in branches %}
{{ dir }}:
  file.absent:
    - require_in:
      - file: /etc/salt/master.d/roots.conf
{% endfor %}

# clone each branch
{% for branch in branches %}
salt-repo-{{ branch }}:
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
      - file: /srv/salt
    - require_in:
      - file: /etc/salt/master.d/roots.conf
{% endfor %}

# manage the file_roots config to generate environments
/etc/salt/master.d/roots.conf:
  file.managed:
    - template: jinja
    - source: salt://{{ slsdir }}/files/roots.conf
    - user: root
    - mode: 644
    - listen_in:
      - service: salt-master