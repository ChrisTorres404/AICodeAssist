# sanitize-hostname

Proves the sanitizer reports internal host names, and leaves public ones alone.

The sanitizer described itself as catching "internal infrastructure" while its
infra rules only covered private IPs, public IPs, SSH connection strings and
`.pem` references. A playbook carrying an internal fully-qualified domain name —
`iam-core.hollow-a.da11.delivery.engineering` — was cleared with "Clear. Safe
to share." Nothing looked at host names at all.

The `infra.hostname` rule closes that, and the interesting half of it is the
half that must stay quiet: `api.github.com`, `docs.python.org`, schema URLs and
dotted identifier chains such as `django.db.models` have the same shape as an
internal FQDN. A rule that fires on those is a rule people learn to ignore, so
this evaluation pins both directions — every internal name in one fixture, no
finding at all in the other.

Severity is asserted too. Host names are a judgement call, so the finding is a
WARNING; were it promoted to CRITICAL it would start failing releases over
names that are perfectly fine to publish.
