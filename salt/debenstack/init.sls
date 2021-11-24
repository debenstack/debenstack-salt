
include:
    - git
    - docker

debenstack-dependencies:
    pkg.installed:
        - pkgs:
            - curl
            - python3-pip

debenstack-dependencies-upgraded:
    cmd.run:
        - name: python -m pip install --upgrade build
        - require:
            - sls: git
            - debenstack-dependencies


debenstack-requirements-installed:
    cmd.run:
        - name: python3 -m pip install -r /repos/debenstack/requirements.txt
        - require:
            - sls: git
            - debenstack-dependencies



generate-debenstack-config:
    file.managed:
        - source: salt://debenstack/files/config.ini.jinja
        - name: /repos/debenstack/config.ini
        - template: jinja
        - user: root
        - group: root
        - mode: 755

debenstack-lib-compiled:
    cmd.run:
        - name: python3 -m build
        - cwd: /repos/debenstack-lib
        - require:
            - sls: git
            - debenstack-dependencies-upgraded

debenstack-lib-installed:
    cmd.run:
        - name: python3 ./setup.py install
        - cwd: /repos/debenstack-lib
        - require:
            - sls: git
            - debenstack-lib-compiled

# Start the bootup and setup of debenstack
initiate-debenstack:
    cmd.run:
        - name: 'sudo ./startup.sh'
        - cwd: /repos/debenstack
        - require:
            - debenstack-requirements-installed
            - generate-debenstack-config
            - debenstack-lib-compiled
            - debenstack-lib-installed
            - sls: git
            - sls: docker