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
        - target: /respos/debenstack
        - http_user: {{ GITHUB_USERNAME }}
        - http_password: {{ GITHUB_TOKEN }}
        - require:
            - repos-directory
            - git-installed

debenstack-lib-cloned:
    git.cloned:
        - name: https://github.com/debenstack/debenstack-lib.git
        - user: root
        - target: /respos/debenstack-lib
        - http_user: {{ GITHUB_USERNAME }}
        - http_password: {{ GITHUB_TOKEN }}
        - require:
            - repos-directory
            - git-installed

