# hook-secret-fixture-pragma

Proves a per-line `acp:allow-secret` pragma lets a fixture that must carry a credential-shaped
string be committed, while an unmarked credential still blocks and the refusal names the pragma.

A security test asserting that a secret is never emitted has to contain the secret it asserts
about. Before this, such a file was permanently uncommittable: the credential rule blocked
unconditionally and the refusal named no way forward. Blanket-exempting test files is not the
answer — a fixture is where a real credential hides best — so the exemption is per line, visible
in the source and to review. The commit hook and `check` must honour the same pragma, or a commit
the one lets through the other refuses.
