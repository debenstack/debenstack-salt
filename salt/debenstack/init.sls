
include:
    - git

dependencies-installed:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            - ca-certificates
            - curl 
            - gnupg2 
            - software-properties-common
            - python3-pip

docker-pkgrepo:
    pkgrepo.managed:
        - humanname: docker
        - name: deb [arch=amd64] https://download.docker.com/linux/debian buster stable
        - file: /etc/apt/sources.list.d/docker.list
        - gpgkey: https://download.docker.com/linux/debian/gpg
        - gpgcheck: 1

install-docker:
    pkg.installed:
        - name: docker-ce
        - fromrepo: docker
        - refresh: True
        - require:
            - docker-pkgrepo
            - dependencies-installed

install-docker-compose:
    cmd.run:
        - name: 'sudo curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'


pip-dependencies-installed:
    cmd.run:
        - name: 'sudo cd /repos/debenstack && python3 -m pip install -r ./requirements.txt'
        - require:
            - dependencies-installed

generate-debenstack-config:
    file.managed:
        - source: salt://debenstack/files/config.ini.jinja
        - name: /repos/debenstack/config.ini
        - user: root
        - group: root
        - mode: 755

debenstack-lib-installed:
    cmd.run:
        - name: python3 /repos/debenstack-lib/setup.py install
        - require:
            - git.debenstack-lib-cloned

# Start the bootup and setup of debenstack
initiate-debenstack:
    cmd.run:
        - name: 'sudo cd /repos/debenstack && ./startup.sh'
        - require:
            - pip-dependencies-installed
            - install-docker
            - install-docker-compose
            - generate-debenstack-config
            - debenstack-lib-installed
            - sls: git