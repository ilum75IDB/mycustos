# Security policy

mycustos runs on database servers with access to MySQL credentials and backup
data, so security reports are taken seriously.

## Supported versions

mycustos is in **pre-release** (`0.x`): only the latest commit of `main` receives
fixes. A support table will be published with version `1.0.0`.

## Reporting a vulnerability

Please **do not open a public issue**. Use GitHub's private reporting instead:
on the repository page open **Security → Report a vulnerability**.

Include, if you can:

- the mycustos version (`mycustos version`), the OS and the Bash version;
- what an attacker can do and under which conditions (local user, config write access, …);
- the steps or a minimal configuration to reproduce it.

**Never include real secrets or infrastructure details**: replace passwords,
hostnames, IP addresses and paths of your environment with placeholders.

Reports are handled on a best-effort basis. You will receive an acknowledgement,
and a fix and an advisory will be published once the issue is confirmed.
Please allow time for the fix before disclosing details publicly.

## Scope

In scope: the code in this repository (`bin/`, `config/*.example`, `contrib/`),
for example command injection, unsafe handling of credentials or temporary
files, or a configuration value that leads to code execution.

Out of scope: vulnerabilities of MySQL, the backup engines or the archiving
software themselves, and installations whose `config/` directory is writable by
untrusted users.
