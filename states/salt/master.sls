{%- set pget = salt['pillar.get'] %} # Convenience alias
{%- import_yaml slspath + "/defaults.yaml" as defaults %}
{%- set user = pget('master', defaults, merge=True) %}