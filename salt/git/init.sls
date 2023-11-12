{% set GITHUB_TOKEN = grains['githubtoken'] %}
{% set GITHUB_USERNAME = grains['githubusername'] %}
{% set GITHUB_RSA_FILE = pillar['git']['rsa_folder'] + '/' + pillar['git']['rsa_file_name'] %}

git-installed:
    pkg.installed:
        - pkgs:
            - git
            - jq

create-github-ssh-key-pair:
    cmd.run:
        - name: ssh-keygen -t rsa -b 4096 -C ben@soernet.ca -f "{{ GITHUB_RSA_FILE }}" -N "" && chmod 400 {{ GITHUB_RSA_FILE }}*
        - unless: test -f {{ GITHUB_RSA_FILE }}

# https://docs.github.com/en/rest/users/keys?apiVersion=2022-11-28
upload-github-ssh-key-to-github:
    cmd.script:
        - name: upload_pub_to_github.sh
        - source: salt://git/files/upload_pub_to_github.jinja
        - template: jinja
        - require:
            - create-github-ssh-key-pair

add-key-to-ssh-agent:
    cmd.run:
        - name: eval `ssh-agent -s` && ssh-add -l |grep -q `ssh-keygen -lf {{ GITHUB_RSA_FILE }} | awk '{print $2}'` || ssh-add {{ GITHUB_RSA_FILE }}
        - require:
            - create-github-ssh-key-pair

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
        - name: git@github.com:debenstack/debenstack.git
        - identity: {{ GITHUB_RSA_FILE }}
        - user: root
        - target: /repos/debenstack
        - require:
            - repos-directory
            - git-installed
            - add-key-to-ssh-agent


debenstack-lib-cloned:
    git.cloned:
        - name: git@github.com:debenstack/debenstack-lib.git
        - identity: {{ GITHUB_RSA_FILE }}
        - user: root
        - target: /repos/debenstack-lib
        - require:
            - repos-directory
            - git-installed
            - add-key-to-ssh-agent

debenstack-backups-cloned:
    git.cloned:
        - name: git@github.com:debenstack/debenstack-backups.git
        - identity: {{ GITHUB_RSA_FILE }}
        - user: root
        - target: /repos/debenstack-backups
        - require:
            - repos-directory
            - git-installed
            - add-key-to-ssh-agent

