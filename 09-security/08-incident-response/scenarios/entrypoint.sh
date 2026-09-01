#!/usr/bin/env bash
set -e

# sudo/auth events go to syslog. With no syslog daemon running there is no
# /var/log/auth.log for the Wazuh agent to read, and exercise 2 produces no alerts at all.
service rsyslog start || rsyslogd || true
service apache2 start || true
service wazuh-agent start || /var/ossec/bin/wazuh-control start

sleep 2
echo "== agent status =="; /var/ossec/bin/wazuh-control status || true

tail -F /var/ossec/logs/ossec.log /var/log/auth.log /var/log/apache2/access.log 2>/dev/null
