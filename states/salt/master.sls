# Copy master config
/etc/salt/master.d/roots.conf:
  file.managed:
    - source: salt://{{ slspath }}/files/master.conf
    - user: root
    - mode: 644
    - listen_in:
      - service: salt-master
