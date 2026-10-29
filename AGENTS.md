# Global agent instructions

Read at the start of every turn in every project on this machine.

## Commit messages

- Never add AI attribution. No "🤖 Generated with ..." line, no "Generated with
  Codebuff" / "Generated with Freebuff", and no `Co-Authored-By:` trailer naming
  Codebuff or Freebuff, in commits or pull-request descriptions.
- End the commit message at its own last line.

`git/hooks/commit-msg` enforces this after the message is written; the rule here
is what stops it being proposed in the first place.
