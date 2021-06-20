nginx:
    user: www-data
    group: www-data

websites:
    - host: bensoer.com
      fullhost: www.bensoer.com
      port: 443
      forward: http://127.0.0.1:2000
    - host: photos.bensoer.com
      fullhost: www.photos.bensoer.com
      port: 443
      forward: http://127.0.0.1:2500
    - host: wiki.bensoer.com
      fullhost: www.wiki.bensoer.com
      port: 443
      forward: http://127.0.0.1:3000
    - host: themountainswontrememberme.com
      fullhost: www.themountainswontrememberme.com
      port: 443
      forward: http://127.0.0.1:3500
    - host: blog.bensoer.com
      fullhost: www.blog.bensoer.com
      port: 443
      forward: http://127.0.0.1:4000
    - host: whereis.bensoer.com
      fullhost: www.whereis.bensoer.com
      port: 443
      forward: http://127.0.0.1:4500
    - host: bnlnkd.me
      fullhost: www.bnlnkd.me
      port: 443
      forward: http://127.0.0.1:5000
    - host: webapp.bnlnkd.me
      fullhost: www.webapp.bnlnkd.me
      port: 443
      forward: http://127.0.0.1:5500
tcp:
    - port: 5055
      forward: 127.0.0.1:5055
udp:
    - port: 5055
      forward: 127.0.0.1:5055
    
      