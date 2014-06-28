mysql-server:
  pkg.latest:
    - pkgs:
      - mysql-server
      - python-mysqldb
  service:
    - name:   mysql
    - enable: True
    - running
    - require:
      - pkg: mysql-server
  mysql_user:
    - name:     {{ pillar['DBSU'] }}
    - password: {{ pillar['DBSUPASS'] }}
    - present
    - require:
      - service: mysql-server