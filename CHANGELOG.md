# Changelog

## 2026-09-25 — Frontend DevSecOps hardening

### Added

- SonarQube Cloud SAST with LCOV coverage and a blocking Quality Gate.
- Dependency security workflow with `npm audit` and GitHub Dependency Review.
- Gitleaks secret scanning across the Git history.
- Trivy container image scanning and Docker/IaC configuration scanning.
- OWASP ZAP baseline DAST against the deployed Azure Static Web App.
- axe-core accessibility checks for WCAG 2 A/AA.

### Security fixes

- Remediated npm dependency findings from 26 total vulnerabilities, including 8 HIGH, to
  14 LOW/MODERATE findings with 0 HIGH and 0 CRITICAL.
- Upgraded the frontend runtime container from the older `nginx:1.27-alpine` base after Trivy
  reported 40 fixable HIGH/CRITICAL findings (38 HIGH, 2 CRITICAL).
- Hardened the Docker image to run as the non-root `nginx` user, resolving Trivy
  misconfiguration `DS-0002`.
- Preserved successful unit tests and production build after dependency remediation.

### Validation

- SonarQube Quality Gate: passed.
- SCA: passed with no HIGH/CRITICAL npm findings.
- Gitleaks: passed.
- Trivy Container & IaC: passed after remediation.
- OWASP ZAP: 58 PASS, 9 WARN, 0 FAIL; workflow intentionally informative.
- axe-core: 0 WCAG 2 A/AA violations.
