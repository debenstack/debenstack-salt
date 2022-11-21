docker-dependencies:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            - ca-certificates
            - curl 
            - gnupg2
            - lsb-release
            - software-properties-common

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
            - docker-ce
            - docker-ce-cli
            - containerd.io
        - refresh: True
        - require:
            - docker-pkgrepo
            - docker-dependencies

docker-running:
    service.running:
        - name: docker
        - restart: True
        - enabled: True
        - reload: True
        - watch:
            - pkg: install-docker
        - require:
            - install-docker

install-docker-compose:
    cmd.run:
        - name: 'sudo curl -L "https://github.com/docker/compose/releases/download/{{ pillar['docker']['compose']['version'] }}/docker-compose-Linux-x86_64" > /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'
        - creates:
            - /usr/local/bin/docker-compose
            - /usr/bin/docker-compose
        - require:
            - docker-dependencies

install-loki-plugin:
    cmd.run:
        - name: 'docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions'
        # if this fails (returns 1) then run loki plugin
        - unless: 'docker plugin ls -f "enabled=true" | grep "loki:latest"'
        - require:
            - install-docker

docker-config:
    file.managed:
        - source: salt://docker/files/daemon.json.jinja
        - name: /etc/docker/daemon.json
        - template: jinja
        - user: root
        - group: root
        - mode: 744
        - require:
            - install-docker
            - install-loki-plugin
        - watch_in:
            - docker-running
