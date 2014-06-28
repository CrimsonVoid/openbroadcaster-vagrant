apache:
  pkg.latest:
    - pkgs:
      - apache2
      - libapache2-mod-php5
  file.absent:
    - name: /etc/apache2/sites-enabled/000-default.conf
    - require:
      - pkg: apache

# Make sure mod_php is enabled
{% for ext in 'conf', 'load' %}
/etc/apache2/mods-enabled/php5.{{ ext }}:
  file.symlink:
    - target: /etc/apache2/mods-available/php5.{{ ext }}
{% endfor %}

# Copy over custom config file
/etc/php5/apache2/php.ini:
  file.managed:
    - source: salt://apache/php.ini
    - user:   root
    - group:  root
    - mode:   644
