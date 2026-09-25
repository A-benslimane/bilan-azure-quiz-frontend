# azure-quiz-frontend

Angular application to review Microsoft certifications (AZ-900 to start, AZ-104 next): review by
module or mock exam, accessible from a simple link (no account). Consumes the REST API of
[azure-quiz-backend](../azure-quiz-backend).


## Stack

- Angular 22 (standalone components, signals), Angular Material, ngx-translate (fr/en)
- Vitest (Angular CLI 22 native test runner)
- ESLint (`angular-eslint`) + Prettier, husky + lint-staged on pre-commit

## Run locally

Prerequisites: Node 22+, and the backend (`azure-quiz-backend`) running on `http://localhost:8080`.

```bash
npm install
npm start   # http://localhost:4200, targets the API on localhost:8080 (see src/environments/environment.development.ts)
```

## Tests and quality

```bash
npm test           # Vitest
npm run test:coverage
npm run lint
npm run format:check
```

## Production build

```bash
npm run build:prod
```

Static output in `dist/azure-quiz-frontend/browser` (that's the folder to point to as
`output_location` when deploying to Azure Static Web Apps).

Before building for a real deployment, update `src/environments/environment.ts` with the deployed
backend API URL (`apiBaseUrl`).


## Structure

- `src/app/core` — models, services (`QuizApiService` for REST calls, `QuizSessionStore` for
  signal-based quiz session state)
- `src/app/features` — pages: `certifications` (home), `modules` (a certification's modules +
  starting a mock exam), `quiz` (question-by-question flow), `results` (final score)

## Out of scope for this repo

- Provisioning the Azure infrastructure (Static Web App, App Service, database).

## DevSecOps security pipeline

The frontend is protected by dedicated GitHub Actions workflows. Security results are visible in
job summaries and, where relevant, downloadable artifacts.

| Category | Tool | Workflow | Policy |
| --- | --- | --- | --- |
| SAST | SonarQube Cloud | `.github/workflows/sast.yml` | Blocking Quality Gate |
| SCA | `npm audit` + GitHub Dependency Review | `.github/workflows/sca.yml` | Blocking on HIGH/CRITICAL |
| Secrets | Gitleaks | `.github/workflows/secrets-scan.yml` | Blocking |
| Container | Trivy image scan | `.github/workflows/container-iac.yml` | Blocking on fixable HIGH/CRITICAL |
| IaC / Docker config | Trivy config scan | `.github/workflows/container-iac.yml` | Blocking on HIGH/CRITICAL |
| DAST | OWASP ZAP Baseline | `.github/workflows/dast.yml` | Informative |
| Accessibility | axe-core | `.github/workflows/accessibility.yml` | Blocking on WCAG 2 A/AA violations |

### SAST vs DAST

**SAST** analyses source code and related static artifacts before the application runs. Here,
SonarQube Cloud scans the Angular/TypeScript sources and imports the LCOV test coverage report.
Its Quality Gate is blocking.

**DAST** analyses a running application from the outside. Here, OWASP ZAP scans the deployed
Azure Static Web App. The DAST workflow is intentionally informative because passive DAST alerts
require review and context before they should block delivery.

Current ZAP baseline evidence: 58 checks passed, 9 warnings, and 0 failures. Reports are uploaded
as the `dast-zap-frontend-report` artifact.

### SCA vs Dependency Review

**SCA** checks the complete dependency graph currently installed by the project. The frontend uses
`npm audit` and blocks the pipeline when HIGH or CRITICAL vulnerabilities are present.

**Dependency Review** only evaluates dependencies introduced or changed by the pull request. It
therefore complements SCA: SCA answers “what is vulnerable now?”, while Dependency Review answers
“what new dependency risk is this PR introducing?”.

### Security remediation evidence

The security pipeline found and remediated real issues during implementation:

- **npm dependencies:** the initial audit reported 26 vulnerabilities, including 8 HIGH. Running
  the controlled dependency remediation updated the lock file and reduced the result to
  14 remaining LOW/MODERATE findings, with **0 HIGH and 0 CRITICAL**. The 15 unit tests and the
  production Angular build still passed after remediation.
- **Container image:** the first Trivy image scan reported **40 fixable HIGH/CRITICAL findings**
  in the previous `nginx:1.27-alpine` runtime image (38 HIGH, 2 CRITICAL). The runtime image was
  upgraded and Alpine packages were refreshed; the follow-up Trivy scan passed.
- **Docker hardening:** Trivy config scan reported `DS-0002` (HIGH) because the image did not
  explicitly run as a non-root user. The Dockerfile now uses `USER nginx`, listens on port 8080,
  and the follow-up IaC scan passes.
- **Accessibility:** axe-core runs against the built frontend with WCAG 2 A/AA rules. The current
  scan reports **0 violations**.

### Blocking and informative controls

Blocking controls stop the pull request when their configured threshold is violated: SonarQube
Quality Gate, SCA HIGH/CRITICAL, Gitleaks, Trivy Container/IaC, and axe-core accessibility.

OWASP ZAP is informative: its report is always preserved for review, but warnings do not
automatically block the pipeline.

