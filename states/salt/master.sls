# Create test file 
test_file_touch:
  file.touch:
    - name: /etc/salt/test.txt
    - makedirs: True

# Append text to test file
test_file_append:
  file.append:
    - name: /etc/salt/test.txt
    - text: |
        # Managed by Salt, do not edit manually!
        Thou hadst better eat salt with the Philosophers of Greece,
        than sugar with the Courtiers of Italy.
        - Benjamin Franklin
    - require:
      - file: test_file_touch

# Template pass file with pillar data
pass_file_template:
  file.managed:
    - name: /etc/salt/pass.txt
    - template: jinja
    - source: salt://{{ slspath }}/files/pass.txt.jinja
    - user: root
    - mode: 644
    - defaults:
        user: {{ pillar['master']['user'] }}
        password: {{ pillar['master']['password'] }}