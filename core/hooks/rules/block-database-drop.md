---
name: block-database-drop
enabled: true
event: bash
pattern: \bdropdb\b|DROP\s+(DATABASE|SCHEMA)\b|DROP\s+TABLE\b.*\bCASCADE\b|TRUNCATE\s+(TABLE\s+)?\w+.*\bCASCADE\b
action: block
---
Dropping a database, schema, or cascading through tables is forbidden without
the user's explicit instruction in this session. If migrations failed, stop
and ask how to proceed; do not reset or recreate the database.
