#!/usr/bin/env bash
set -e
service wazuh-agent start || /var/ossec/bin/wazuh-control start
service apache2 start || true
tail -F /var/ossec/logs/ossec.log /var/log/apache2/access.log 2>/dev/null
