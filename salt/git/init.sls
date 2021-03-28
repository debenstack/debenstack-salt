{% set GITHUB_TOKEN = grains['githubtoken'] %}
{% set GITHUB_USERNAME = pillar['git']['username'] %}

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

