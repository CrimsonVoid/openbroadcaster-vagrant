ob-pkgs:
  pkg.latest:
    - pkgs:
      # Media
      - python-gst0.10
      - python-gobject
      - gstreamer0.10-plugins-base
      - gstreamer0.10-plugins-good
      - gstreamer0.10-plugins-bad
      - gstreamer0.10-plugins-ugly
      - libav-tools
      - vorbis-tools
      # PHP
      {% for pkg in 'curl', 'gd', 'imagick', 'mcrypt', 'mysql' %}
      - php5-{{ pkg }}
      {% endfor %}
      # Extras
      - apg
      - festival
      - unzip
  file.directory:
    - name:     /opt/openbroadcaster
    - user:     vagrant
    - group:    vagrant
    - makedirs: True
    - dir_mode: 755
  cmd.script:
    - name:     salt://openbroadcaster/get-ob.sh
    - source:   salt://openbroadcaster/get-ob.sh
    - user:     vagrant
    - group:    vagrant
    - cwd:      /opt/openbroadcaster
    - stateful: True
    - unless:   test -d /opt/openbroadcaster/Server-master
    - require:
      - file: ob-pkgs

ob-install:
  cmd.script:
    - name:     /opt/openbroadcaster/Server-master/ob.installer.sh
    - source:   salt://openbroadcaster/ob.installer.sh
    - user:     root
    - group:    root
    - cwd:      /opt/openbroadcaster/Server-master
    - shell:    /bin/bash
    - template: jinja
    - unless:   test -d {{ pillar['WEBROOT'] }}
    - defaults:
      WEBROOT:   {{ pillar['WEBROOT']   }}
      MEDIAROOT: {{ pillar['MEDIAROOT'] }}
      WEBUSER:   {{ pillar['WEBUSER']   }}
      OBUSER:    {{ pillar['OBUSER']    }}

      DBSU:     {{ pillar['DBSU']     }}
      DBSUPASS: {{ pillar['DBSUPASS'] }}
      OBDBNM:   {{ pillar['OBDBNM']   }}
      OBDBUSER: {{ pillar['OBDBUSER'] }}
      OBDBPASS: {{ pillar['OBDBPASS'] }}
      DBHOST:   {{ pillar['DBHOST']   }}
      TBLPRE:   {{ pillar['TBLPRE']   }}

      CSSPRE: {{ pillar['CSSPRE'] }}
      OBFQDN: {{ pillar['OBFQDN'] }}
      OBIP:   {{ pillar['OBIP']   }}

      OBRPLYML:    {{ pillar['OBRPLYML']    }}
      OBMLNM:      {{ pillar['OBMLNM']      }}
      OBADMINPASS: {{ pillar['OBADMINPASS'] }}
      OBSALT:      {{ pillar['OBSALT']      }}
    - require:
      - cmd: ob-pkgs

ob-apache:
  file.symlink:
    - name:   /etc/apache2/sites-enabled/ob.apache.conf
    - target: /etc/apache2/sites-available/ob.apache.conf
    - require:
      - cmd: ob-install

ob-service:
  file.directory:
    - name:      /var/log/apache2/{{ pillar['OBFQDN'] }}
    - user:      www-data
    - group:     adm
    - makedirs:  True
    - dir_mode:  755
    - require_in:
      - service: ob-service
  service:
    - name:   apache2
    - enable: True
    - running
    - watch:
      - file: ob-apache