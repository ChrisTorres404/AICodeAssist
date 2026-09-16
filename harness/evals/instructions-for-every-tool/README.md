# instructions-for-every-tool

Checks that the methodology reaches whichever agent is running, not only Claude Code.

Codex, Cursor and most agents read `AGENTS.md`; Claude Code reads `CLAUDE.md` and can import.
So the instructions live once, in `AGENTS.md`, and `CLAUDE.md` points at them. A project's own
files are never overwritten, and `detect-stack --write` refreshes the file that carries the stack lines.
