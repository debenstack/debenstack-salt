{% set GITHUB_TOKEN = grains['githubtoken'] %}
{% set GITHUB_USERNAME = grains['githubusername'] %}

{% set GITHUB_RSA_FILE = pillar['git.rsa_folder'] + '/' + pillar['git.rsa_file_name'] %}



git-installed:
    pkg.installed:
        - pkgs:
            - git

create-github-ssh-key-pair:
    cmd.run:
        - name: ssh-keygen -t rsa -b 4096 -C ben@soernet.ca -f "{{ GITHUB_RSA_FILE }}" -N "" && chmod 400 {{ GITHUB_RSA_FILE }}*
        - unless: test -f /etc/ssh/github_rsa

# https://docs.github.com/en/rest/users/keys?apiVersion=2022-11-28
upload-github-ssh-key-to-github:
    cmd.script:
        - name: upload_pub_to_github.sh
        - source: salt://git/files/upload_pub_to_github.jinja
        - template: jinja
        - require:
            - create-github-ssh-key-pair

# https://stackoverflow.com/questions/7875540/how-to-write-multiple-line-string-using-bash-with-variables
# https://superuser.com/questions/232373/how-to-tell-git-which-private-key-to-use
update-ssh-config:
    cmd.script:
        - name: salt://git/files/update_ssh_config.sh
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
            - update-ssh-config

debenstack-lib-cloned:
    git.cloned:
        - name: git@github.com:debenstack/debenstack-lib.git
        - identity: {{ GITHUB_RSA_FILE }}
        - user: root
        - target: /repos/debenstack-lib
        - require:
            - repos-directory
            - git-installed
            - update-ssh-config

debenstack-backups-cloned:
    git.cloned:
        - name: git@github.com:debenstack/debenstack-backups.git
        - identity: {{ GITHUB_RSA_FILE }}
        - user: root
        - target: /repos/debenstack-backups
        - require:
            - repos-directory
            - git-installed
            - update-ssh-config

