
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
        - key_url: https://download.docker.com/linux/debian/gpg
        - clean_file: True
        - gpgcheck: 1

install-docker:
    pkg.installed:
        - pkgs:
            - docker-ce: {{ pillar['docker']['ce']['version'] }}
            - docker-ce-cli: {{ pillar['docker']['ce-cli']['version'] }}
            - containerd.io: {{ pillar['docker']['containerdio']['version'] }}
        - refresh: True
        - require:
            - docker-pkgrepo
            - dependencies-installed

install-docker-compose:
    cmd.run:
        - name: 'sudo curl -L "https://github.com/docker/compose/releases/download/{{ pillar['docker']['compose']['version'] }}/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'

debenstack-requirements-installed:
    cmd.run:
        - name: python3 -m pip install -r /repos/debenstack/requirements.txt
        - require:
            - sls: git
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
        - name: python3 ./setup.py install
        - cwd: /repos/debenstack-lib
        - require:
            - sls: git

# Start the bootup and setup of debenstack
initiate-debenstack:
    cmd.run:
        - name: 'sudo cd /repos/debenstack && ./startup.sh'
        - require:
            - debenstack-requirements-installed
            - install-docker
            - install-docker-compose
            - generate-debenstack-config
            - debenstack-lib-installed
            - sls: git