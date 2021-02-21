

packages-installed:
    pkg.installed:
        - pkgs:
            - certbot
            - openssl

nginx:
    pkg.installed:
        - name: nginx
    service.running:
        - require:
            - packages-installed
            - streams-dir
        - name: nginx
        - restart: True
        - watch:
            - pkg: nginx
            - file: nginx
            - file: /etc/nginx/sites-available/*
            - file: /etc/nginx/sites-enabled/*
    file.managed:
        - source: salt://nginx/files/nginx.conf.jinja
        - name: /etc/nginx/nginx.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755

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
        - watch_in:
            - service: nginx
        - context:
            PORT : {{ udpstream["port"] }}
            FORWARD : {{ udpstream["forward"] }}
        - required:
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
        - watch_in:
            - service: nginx
        - context:
            PORT: {{ tcpstream["port"] }}
            FORWARD: {{ tcpstream["forward"] }}
        - required:
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
        - watch_in:
            - service: nginx
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
        - require:
            - {{website['fullhost']}}-website-conf



{% endfor %}

# Remove defailt
nginx-default-site-removed:
    file.absent:
        - names:
            - /etc/nginx/sites-available/default
            - /etc/nginx/sites-enabled/default
        - require:
            - pkg: nginx


#certbot.bensoer.com-conf:
#    file.managed:
#        - source: salt://nginx/files/certbot.bensoer.com.conf.jinja
#        - name: /etc/nginx/sites-available/certbot.bensoer.com.conf
#        - user: www-data
#        - group: www-data
#        - mode: 755
#certbot.bensoer.com-symlink:
#    file.symlink:
#        - name: /etc/nginx/sites-enabled/certbot.bensoer.com.conf
#        - target: /etc/nginx/sites-available/certbot.bensoer.com.conf
#        - user: www-data
#        - group: www-data
#        - mode: 755
#        - require:
#            - certbot.bensoer.com-conf

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

{% for website in pillar.get('websites', []) %}
{% set CERT_PATH = '/etc/letsencrypt/live/' + website["host"] %}
{% if not salt['file.directory_exists'](CERT_PATH) %}
{{website['fullhost']}}-generate-certs:
    cmd.run:
        - name: 'sudo certbot certonly --agree-tos --email "ben@soernet.ca" --webroot -w /var/lib/letsencrypt/ -d {{website["host"]}} -d {{website["fullhost"]}}'
        - require:
            - {{website["fullhost"]}}-letsencrypt-config

# maybe will work as a post-hook ?
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
        - onchanges:
            - cmd: {{website['fullhost']}}-generate-certs
        - watch_in:
            - service: nginx
        - require:
            - letsencrypt-conf
            - ssl-conf
            - deffie-hellman
            - acme-challenge
{% endif %}
{% endfor %}