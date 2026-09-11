export const meta = {
  name: 'wo-review',
  description: 'Review a work order\'s diff across quality, security, and evidence dimensions, then adversarially verify every blocking finding before closeout.',
  whenToUse: 'Before closing a work order: pass the unified diff, the WO number, and the language.',
  phases: [
    { title: 'Review', detail: 'one reviewer per dimension, in parallel' },
    { title: 'Verify', detail: 'two skeptics try to refute each CRITICAL/HIGH finding' },
  ],
};

// ---------------------------------------------------------------------------
// The review phase of the work-order lifecycle as a deterministic fan-out.
//
// args: { diff: string, wo?: string, language?: string, changedFiles?: string[] }
// Returns: { verdict: 'APPROVE' | 'CHANGES_REQUESTED', blocking: [], advisory: [], stats: {} }
//
// The caller (the main session) owns the human gate: it decides whether to
// draft the closeout on APPROVE, and it never closes on CHANGES_REQUESTED.
// ---------------------------------------------------------------------------

const a = args || {};
if (!a.diff || typeof a.diff !== 'string' || !a.diff.trim()) {
  throw new Error('wo-review: args.diff (unified diff text) is required');
}
const diff = a.diff;
const wo = a.wo || 'unnumbered';
const language = (a.language || '').toLowerCase();
const changed = Array.isArray(a.changedFiles) ? a.changedFiles : [];

const LANGUAGE_AGENT = {
  typescript: 'typescript-expert', javascript: 'typescript-expert', python: 'python-expert',
  react: 'react-expert', nestjs: 'nestjs-expert', nextjs: 'nextjs-expert', postgres: 'postgres-expert',
};
const SECURITY_TRIGGER = /\b(auth|login|password|token|secret|credential|api[_-]?key|session|jwt|oauth|cookie|sql|query|exec|eval|crypto|hash|hmac|readFile|writeFile|fetch|axios|subprocess)\b/i;

const FINDINGS = {
  type: 'object',
  properties: {
    findings: { type: 'array', items: { type: 'object', properties: {
      severity: { type: 'string', enum: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'] },
      file: { type: 'string' }, line: { type: 'integer' },
      title: { type: 'string' }, detail: { type: 'string' },
    }, required: ['severity', 'file', 'title', 'detail'] } },
  }, required: ['findings'],
};
const VERDICT = { type: 'object', properties: {
  refuted: { type: 'boolean' }, reason: { type: 'string' } }, required: ['refuted', 'reason'] };

const dims = [
  { key: 'quality', agentType: 'project-validator-expert',
    prompt: `Review this diff for WO-${wo} against the project's code-quality rules: no stubs, no debug logging, no unverified references to files/tables/methods, explicit error handling, no magic numbers, proper types. Report each problem as a finding with severity.\n\n${diff}` },
  { key: 'evidence', agentType: 'project-validator-expert',
    prompt: `This diff belongs to WO-${wo}. Determine whether the change is covered by behavioral tests that were EXECUTED, not merely planned. Look for test files in the diff and for verification claims. A claim of PASS with no execution output is a CRITICAL finding. Missing tests for a behavior change is HIGH.\n\n${diff}` },
];
if (LANGUAGE_AGENT[language]) {
  dims.push({ key: language, agentType: LANGUAGE_AGENT[language],
    prompt: `Review this diff for ${language}-specific problems: idioms, type safety, framework misuse, performance traps. Findings only, with severity.\n\n${diff}` });
}
if (SECURITY_TRIGGER.test(diff) || changed.some(f => SECURITY_TRIGGER.test(f))) {
  dims.push({ key: 'security', agentType: 'owasp-top10-expert',
    prompt: `This diff touches a security-sensitive path. Review it for OWASP Top 10 issues, secret handling, injection, authz gaps, and unsafe defaults. Findings only, with severity.\n\n${diff}` });
}
log(`WO-${wo}: reviewing across ${dims.length} dimensions (${dims.map(d => d.key).join(', ')})`);

// Review each dimension, then verify its blocking findings, with no barrier
// between dimensions — a fast reviewer's findings get verified while slow ones run.
const results = await pipeline(
  dims,
  d => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS, agentType: d.agentType })
        .then(r => ({ key: d.key, findings: (r && r.findings) || [] })),
  async (r) => {
    if (!r) return null;
    const blocking = r.findings.filter(f => f.severity === 'CRITICAL' || f.severity === 'HIGH');
    const advisory = r.findings.filter(f => f.severity === 'MEDIUM' || f.severity === 'LOW');
    const verified = await parallel(blocking.map((f, i) => () =>
      parallel([0, 1].map(k => () =>
        agent(`Try to REFUTE this ${f.severity} review finding on WO-${wo}. Default to refuted=true if you cannot reproduce or confirm it from the diff.\n\nFinding: ${f.title}\n${f.detail}\nFile: ${f.file}${f.line ? ':' + f.line : ''}\n\nDiff:\n${diff}`,
          { label: `verify:${r.key}:${i}:${k}`, phase: 'Verify', schema: VERDICT })))
        .then(votes => {
          const v = votes.filter(Boolean);
          const refuted = v.length === 2 && v.every(x => x.refuted);
          return { ...f, dimension: r.key, confirmed: !refuted, reasons: v.map(x => x.reason) };
        })));
    return { key: r.key, blocking: verified.filter(Boolean), advisory: advisory.map(f => ({ ...f, dimension: r.key })) };
  },
);

const ok = results.filter(Boolean);
const blocking = ok.flatMap(r => r.blocking.filter(f => f.confirmed));
const refuted = ok.flatMap(r => r.blocking.filter(f => !f.confirmed));
const advisory = ok.flatMap(r => r.advisory).concat(refuted.map(f => ({ ...f, note: 'refuted by both skeptics' })));
const failed = dims.length - ok.length;
if (failed) log(`${failed} review dimension(s) failed to run — treating as CHANGES_REQUESTED`);

return {
  verdict: blocking.length || failed ? 'CHANGES_REQUESTED' : 'APPROVE',
  wo, blocking, advisory,
  stats: { dimensions: dims.length, failed, blocking: blocking.length, refuted: refuted.length, advisory: advisory.length },
};
