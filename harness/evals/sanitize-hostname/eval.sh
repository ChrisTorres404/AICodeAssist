#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; mkdir -p leaky clean

# --- names that must be reported -------------------------------------------
# Reserved private suffixes, and depth under a top-level domain no public
# documentation uses. Every line here is a finding; the line numbers are the
# assertion, so keep the file and the expected list in step.
cat > leaky/notes.md <<'EOF'
Deploy target: iam-core.hollow-a.da11.delivery.engineering
Database host: pg-primary-02.db.svc.cluster.internal
Bastion: jump1.corp
Printer: officejet.home.arpa
Mail relay: relay.eu-west-1.mail.aws-internal
EOF
out="$("$PIPELINE_ROOT/bin/sanitize" leaky)"; rc=$?
[ "$rc" -eq 1 ] || { echo "internal host names did not give PASS WITH WARNINGS (exit $rc)"; echo "$out"; exit 1; }
hits="$(printf '%s\n' "$out" | sed -n 's/^- \*\*\[infra\.hostname\]\*\* `notes\.md:\([0-9]*\)`.*/\1/p' | sort -n | tr '\n' ' ')"
[ "$hits" = "1 2 3 4 5 " ] || { echo "infra.hostname fired on lines [$hits]; every line of the fixture is an internal host"; echo "$out"; exit 1; }
# a host name is a guess, so it must never be the thing that fails a release
printf '%s\n' "$out" | grep -q "^## Critical findings (0)" || { echo "host names were reported as CRITICAL"; echo "$out"; exit 1; }

# --- names that must not be reported ---------------------------------------
# Public documentation hosts, schema URLs, template slots, dotted identifier
# chains, filenames and version numbers all have an internal FQDN's shape.
cat > clean/notes.md <<'EOF'
Docs live at https://docs.python.org/3/library/re.html
API calls go to https://api.github.com/repos/owner/repo
Marketing site: example.com and api.example.com and cdn.jsdelivr.net
Schema: https://json-schema.org/draft-07/schema and http://www.w3.org/2001/XMLSchema
Dev server: http://localhost:3001/api/v1
Template slots: {{API_HOST}}.{{TENANT_DOMAIN}} and <host-name.internal>
Python: os.path.join(a, b), django.db.models, pytest.mark.slow, @pytest.mark.unit
Files: core/config/settings.hooks.json, pipeline.config.example.sh, build.gradle.kts
Versions: 1.0.0, v2.11.4, and the loopback 127.0.0.1
Reverse-proxy config: Caddyfile.local
EOF
out="$("$PIPELINE_ROOT/bin/sanitize" clean)"; rc=$?
[ "$rc" -eq 0 ] || { echo "ordinary documentation hosts were reported (exit $rc)"; echo "$out"; exit 1; }
exit 0
