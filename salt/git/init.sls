{% set GITHUB_TOKEN = salt['config.get']('githubtoken') %}
{% set GITHUB_USERNAME = salt['config.get']('githubusername') %}



git-installed:
    pkg.installed:
        - pkgs:
            - git

repos-directory:
  file.directory:
    - name: /repos
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 755
    - recurse:
      - user
      - group
      - mode

debenstack-cloned:
    git.cloned:
        - name: https://github.com/debenstack/debenstack.git
        - user: root
        - target: /repos/debenstack
        - https_user: {{ GITHUB_USERNAME }}
        - https_pass: {{ GITHUB_TOKEN }}
        - require:
            - repos-directory
            - git-installed

debenstack-lib-cloned:
    git.cloned:
        - name: https://github.com/debenstack/debenstack-lib.git
        - user: root
        - target: /repos/debenstack-lib
        - https_user: {{ GITHUB_USERNAME }}
        - https_pass: {{ GITHUB_TOKEN }}
        - require:
            - repos-directory
            - git-installed

debenstack-requirements-installed:
    cmd.run:
        - name: python3 -m pip install -f /repos/debenstack/requirements.txt
        - require:
            - debenstack-cloned

debenstack-backups-cloned:
    git.cloned:
        - name: https://github.com/debenstack/debenstack-backups.git
        - user: root
        - target: /repos/debenstack-backups
        - https_user: {{ GITHUB_USERNAME }}
        - https_pass: {{ GITHUB_TOKEN }}
        - require:
            - repos-directory
            - git-installed

