# Variables
master:
  user: jamfox
  password: hunter2

# Schedules
schedule:
  pull_latest_git:
    function: salt.refresh_repo
    cron: '* * * * *'
