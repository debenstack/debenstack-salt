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
        - name: eval `ssh-agent -s` && ssh-add {{ GITHUB_RSA_FILE }}
        - require: 
            - create-github-ssh-key-pair

# https://stackoverflow.com/questions/7875540/how-to-write-multiple-line-string-using-bash-with-variables
# https://superuser.com/questions/232373/how-to-tell-git-which-private-key-to-use
update-ssh-config:
    cmd.script:
        - name: update_ssh_config.jinja
        - source: salt://git/files/update_ssh_config.jinja
        - template: jinja
        - require:
            - create-github-ssh-key-pair

create-global-known-hosts-file:
    cmd.run:
        - name: touch /etc/ssh/ssh_known_hosts
        - create: /etc/ssh/ssh_known_hosts

add-github-to-known-hosts-file:
    cmd.run:
        - name: ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts
        - unless: grep 'github.com' /etc/ssh/ssh_known_hosts
        - require:
            - create-global-known-hosts-file

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
            - update-ssh-config
            - add-github-to-known-hosts-file


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
            - update-ssh-config
            - add-github-to-known-hosts-file

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
            - update-ssh-config
            - add-github-to-known-hosts-file

