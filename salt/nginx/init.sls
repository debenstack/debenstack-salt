

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
            - file: /etc/nginx/nginx.conf
            - file: /etc/nginx/sites-enabled/*
            - file: /etc/nginx/streams.d/*
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

websites-conf:
    file.managed:
        - source: salt://nginx/files/websites.conf.jinja
        - template: jinja
        - show_changes: True
        - name: /etc/nginx/sites-available/websites.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - require:
            - letsencrypt-conf
            - ssl-conf
            - deffie-hellman
            - acme-challenge
websites-conf-symlink:
    file.symlink:
        - name: /etc/nginx/sites-enabled/websites.conf
        - target: /etc/nginx/sites-available/websites.conf
        - user: {{ pillar['nginx']['user'] }}
        - group: {{ pillar['nginx']['group'] }}
        - mode: 755
        - require:
            - websites-conf


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
        - required:
            - letsencrypt-config-dir
{% endfor %}