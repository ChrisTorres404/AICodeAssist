# Skill Packs

Optional skill collections for work outside general software engineering.
Nothing here is installed unless you ask for it: set `SKILL_PACKS` in
`pipeline.config.sh` (space-separated), or pass `--skill-pack <name>` to
`new-project`. The `full` install profile installs every pack.

| Pack | Skills | For |
|---|---|---|
| `business-ops` | billing, investor materials, agreements, e-signature, email and messaging ops, workspace ops, knowledge and research ops, issue-tracker integration | back-office and operations automation |
| `healthcare` | EMR and clinical-decision-support patterns, PHI handling, HIPAA, a healthcare evaluation harness | regulated health software |
| `marketing` | brand discovery and voice, content engine, SEO, social publishing, campaigns, growth log, lead intelligence, market and competitive research, product lens, X API | go-to-market and content |
| `media` | video generation, motion, icon generation, design finishes, 3D state inspection | media production pipelines |
| `ml` | ML adoption, MLE workflow, recommender pipelines, GAN-style build-critique loops | machine-learning delivery |
| `network` | home-lab readiness and setup, DNS, VLANs, WireGuard, BGP diagnostics, config validation, interface health, SSH automation, Cisco IOS | network engineering |
| `science` | PubMed and USPTO queries, genomics package usage, literature review, scholar evaluation | research software |
| `supply-chain` | carriers, customs, logistics exceptions, returns, demand planning, production scheduling, nonconformance, energy procurement, counterparty channels | logistics and manufacturing |
| `web3` | AMM security, token decimals, keccak hashing, prediction-market research and risk, trading-agent security, agent payments | blockchain and DeFi |

Every skill follows the same shape as `core/skills/` and ends with the
"In this pipeline" footer that ties it to the work-order lifecycle. Add a
pack by creating a directory here; `acp lint` validates it like any skill.
