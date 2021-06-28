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
            - docker-ce: {{ pillar['docker']['ce']['version'] }}
            - docker-ce-cli: {{ pillar['docker']['ce-cli']['version'] }}
            - containerd.io: {{ pillar['docker']['containerdio']['version'] }}
        - refresh: True
        - require:
            - docker-pkgrepo
            - docker-dependencies

install-docker-compose:
    cmd.run:
        - name: 'sudo curl -L "https://github.com/docker/compose/releases/download/{{ pillar['docker']['compose']['version'] }}/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose && sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose'
        - require:
            - docker-dependencies
