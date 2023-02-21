# Base environment is the default/production environment
base:
  'salt':
    - salt.refresh_repo
    - salt.master
