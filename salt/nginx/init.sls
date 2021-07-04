

packages-installed:
    pkg.installed:
        - pkgs:
            - certbot
            - openssl

nginx-installed:
    pkg.installed:
        - name: nginx
        - require:
            - packages-installed

nginx-running:
    service.running:
        - name: nginx
        - restart: True
        - enabled: True
        - reload: True
        - watch:
            - pkg: nginx-installed
            - file: nginx-conf
            - file: /etc/nginx/sites-available/*
            - file: /etc/nginx/sites-enabled/*
        - require:
            - nginx-enabled
            - nginx-installed
            - nginx-conf
nginx-conf:
    file.managed:
        - source: salt://nginx/files/nginx.conf.jinja
        - name: /etc/nginx/nginx.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755

nginx-enabled:
    service.enabled:
        - name: nginx
        - require:
            - nginx-installed
            - nginx-running
            - nginx-conf


streams-dir:
    file.directory:
        - name: /etc/nginx/streams.d/
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - makedirs: True
        - recurse:
            - mode
            - user
            - group

{% for udpstream in pillar.get('udp', [])%}
stream-udp-{{udpstream["port"]}}:
    file.managed:
        - source: salt://nginx/files/stream.udp.conf.jinja
        - name: /etc/nginx/streams.d/stream-udp-{{udpstream["port"]}}.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - template: jinja
        - require_in:
            - nginx-running
        - context:
            PORT : {{ udpstream["port"] }}
            FORWARD : {{ udpstream["forward"] }}
            ADDRESS: {{ salt['network.ip_addrs']('eth0', type='public')[0] }}
        - require:
            - streams-dir
{% endfor %}

{% for tcpstream in pillar.get('tcp', [])%}
stream-tcp-{{tcpstream["port"]}}:
    file.managed:
        - source: salt://nginx/files/stream.tcp.conf.jinja
        - name: /etc/nginx/streams.d/stream-tcp-{{tcpstream["port"]}}.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - template: jinja
        - require_in:
            - nginx-running
        - context:
            PORT: {{ tcpstream["port"] }}
            FORWARD: {{ tcpstream["forward"] }}
            ADDRESS: {{ salt['network.ip_addrs']('eth0', type='public')[0] }}
        - require:
            - streams-dir
{% endfor %}


deffie-hellman:
    cmd.run:
        - name: "openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048"
        - creates:
            - /etc/ssl/certs/dhparam.pem
        - require:
            - packages-installed

acme-challenge:
    file.directory:
        - name: /var/lib/letsencrypt/.well-known
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - makedirs: True
        - recurse:
            - user
            - group
            - mode

letsencrypt-conf:
    file.managed:
        - source: salt://nginx/files/letsencrypt.nginx.conf.jinja
        - name: /etc/nginx/snippets/letsencrypt.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755

ssl-conf:
    file.managed:
        - source: salt://nginx/files/ssl.conf.jinja
        - name: /etc/nginx/snippets/ssl.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755



# Remove default page
nginx-default-site-removed:
    file.absent:
        - names:
            - /etc/nginx/sites-available/default
            - /etc/nginx/sites-enabled/default
        - require:
            - pkg: nginx-installed


letsencrypt-config-dir:
  file.directory:
    - name: /etc/letsencrypt/configs
    - makedirs: true
    - user: {{ pillar['nginx']['user'] }}
    - group: {{ pillar['nginx']['group'] }}
    - mode: 755
    - recurse:
        - mode
        - user
        - group

{% for website in pillar.get('websites', []) %}
{{website["fullhost"]}}-letsencrypt-config:
    file.managed:
        - name: /etc/letsencrypt/configs/{{website["host"]}}.conf
        - source: salt://nginx/files/letsencrypt.certbot.conf.jinja
        - template: jinja
        - context:
            SERVER_NAME : {{ website["host"] }}
        - require:
            - letsencrypt-config-dir
{% endfor %}

letencrypt-renew-nginx-restart:
    file.append:
        - name: /etc/letsencrypt/cli.ini
        - text: 'deploy-hook = systemctl reload nginx'
        - require:
            - packages-installed



# 1) Generate the initial configurations
{% for website in pillar.get('websites', []) %}
{% set CERT_PATH = '/etc/letsencrypt/live/' + website["host"] %}
{{website["fullhost"]}}-website-conf:
    file.managed:
        - source: salt://nginx/files/websites.conf.jinja
        - template: jinja
        - show_changes: True
        - name: /etc/nginx/sites-available/{{website["host"]}}.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - context:
            WEBSITE : {{ website }}
            CERT_PATH : {{ CERT_PATH }}
        - require_in:
            - nginx-running
            - restart-nginx
        - require:
            - letsencrypt-conf
            - ssl-conf
            - deffie-hellman
            - acme-challenge
{{website["fullhost"]}}-website-conf-symlink:
    file.symlink:
        - name: /etc/nginx/sites-enabled/{{website["host"]}}.conf
        - target: /etc/nginx/sites-available/{{website["host"]}}.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - require_in:
            - nginx-running
            - restart-nginx
        - require:
            - {{website['fullhost']}}-website-conf
{% endfor %}

# 2) Restart Nginx
restart-nginx:
    cmd.run:
        - name: 'sudo systemctl restart nginx'
        - require:
            - nginx-default-site-removed
            - nginx-conf

# 3) Make certbot Calls
{% for website in pillar.get('websites', []) %}
{% set CERT_PATH = '/etc/letsencrypt/live/' + website["host"] %}
{% if not salt['file.directory_exists'](CERT_PATH) %}
{{website['fullhost']}}-generate-certs:
    cmd.run:
        - name: 'sudo certbot certonly --agree-tos --email "ben@soernet.ca" --webroot -w /var/lib/letsencrypt/ -d {{website["host"]}} -d {{website["fullhost"]}}'
        - require:
            - {{website["fullhost"]}}-letsencrypt-config
            - {{website["fullhost"]}}-website-conf
            - {{website["fullhost"]}}-website-conf-symlink
            - restart-nginx

# 4) Regenerate the configurations
{{website["fullhost"]}}-website-conf-rebuild:
    file.managed:
        - source: salt://nginx/files/websites.conf.jinja
        - template: jinja
        - show_changes: True
        - name: /etc/nginx/sites-available/{{website["host"]}}.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - context:
            WEBSITE : {{ website }}
            CERT_PATH : {{ CERT_PATH }}
        - require:
            - {{website['fullhost']}}-generate-certs
            - letsencrypt-conf
            - ssl-conf
            - deffie-hellman
            - acme-challenge
            - restart-nginx
{% endif %}
{% endfor %}