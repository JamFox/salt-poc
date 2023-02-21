# Variables
master:
  user: jamfox
  password: hunter2

# Schedules
schedule:
  pull_latest_git:
    function: state.sls
    args:
      - salt.refresh_repo
    kwargs:
      pillarenv: base
      saltenv: base
    cron: '* * * * *'
