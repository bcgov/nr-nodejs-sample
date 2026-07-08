# Application Context

This file is the authoritative source for repository-specific exposure and business context used in vulnerability scoring.

## Metadata

- Application name: nr-nodejs-sample [Confirmed]
- Repository: bcgov/nr-nodejs-sample [Confirmed]
- Owner/team: bcgov [Confirmed], specific team unknown [Inferred]
- Last updated: 2026-06-19 [Confirmed]
- Updated by: Copilot bootstrap from repo evidence [Inferred]

Evidence:
- `catalog-info.yaml` (`metadata.name`, `github.com/project-slug`, `spec.owner`)

## Deployment Model

- Runtime platform: Node.js 24 NestJS service built into OCI artifact [Confirmed]
- Network placement: On-prem deployment pipeline integration exists; exact runtime network segment not documented [Inferred]
- Environment(s): development, test, production [Confirmed]
- Authentication boundary: CI/CD uses GitHub tokens and broker JWT for build/deploy orchestration; no runtime application authentication is required [Confirmed]
- Trust zones: GitHub Actions -> Broker/CD systems -> target runtime environments [Inferred]

Evidence:
- `catalog-info.yaml` (`playbook.io.nrs.gov.bc.ca/nodeVersion`, `deployType: nodejs`, `composer...gh-oci-deploy-onprem`)
- `.github/workflows/run-deploy-nodejs-sample.yaml` (environment choices)
- `.github/workflows/deploy-nodejs-sample.yaml` (broker + cd integration)
- `.github/workflows/build-release-nodejs-sample.yaml` (OCI artifact publish)

## Exposure Classification

Select one and explain:

- External internet-facing: Yes, production only [Confirmed]
- Internal-only service: Yes, development and test only, accessible only through VPN-connected internal access paths [Confirmed]
- Hybrid exposure: Yes [Confirmed]

Initial classification for analysis: Hybrid exposure. Score production as internet-facing and development and test as VPN-restricted internal [Confirmed].

## Exposure Details

- Public endpoint(s):
	- Production: Internet-exposed endpoint(s) [Confirmed]
	- Development/test: No public endpoint exposure documented; internal access only [Confirmed]
- Access path:
	- Production: Public ingress path [Confirmed]
	- Development/test: VPN-restricted internal access only [Confirmed]
- Ingress controls (WAF/API gateway/LB):
	- Production: Not documented in repo [Confirmed-as-unknown]
	- Development/test: Not documented in repo [Confirmed-as-unknown]
- Source network restrictions:
	- Production: Not VPN-only [Confirmed]
	- Development/test: VPN required [Confirmed]
- East-west/internal reachable components: Not documented in repo [Confirmed-as-unknown]

## Data Sensitivity

- Data classes processed: No explicit domain data classification in repository [Confirmed-as-unknown]
- Personal information involved: Not documented [Confirmed-as-unknown]
- Regulatory/compliance considerations: OCIO patch governance applies; additional data regulations not documented [Confirmed + Inferred]

Evidence:
- No data model/domain sensitivity declarations found in current repository metadata/readme/workflows.

## Business Criticality

- Service criticality tier: experimental lifecycle indicates non-production-grade maturity posture for software lifecycle; production deployment path still exists [Confirmed + Inferred]
- Core business functions supported: sample/reference Node.js service used in pipeline ecosystem [Inferred]
- Availability impact if compromised/unavailable: likely low to medium for direct business process, medium for platform/dev workflow impact [Inferred]
- Integrity impact if tampered: medium due to CI/CD and artifact pipeline implications [Inferred]
- Confidentiality impact if disclosed: unknown; no sensitive data classifications documented [Confirmed-as-unknown]

Evidence:
- `catalog-info.yaml` (`spec.lifecycle: experimental`, description/title)
- `README.md` (sample/starter framing + Polaris pipeline usage)

## Compensating Controls

- Preventive controls:
	- CI preflight/build/deploy gates and environment approvals in workflow chain [Confirmed]
	- Branch/PR mergeability checks before deployment build path [Confirmed]
- Detective controls:
	- Test workflow (`npm test`) in CI [Confirmed]
	- Dependabot alerts present in GitHub Security and quality tab [Confirmed from team statement]
- Response controls:
	- Deployment promotion path (development -> test -> production) supports staged response [Confirmed]
	- Risk acceptance process reference still required from owning team [Inferred]

## Risk Notes

- Known operational constraints affecting patch timelines:
	- Dependency updates must pass CI tests/build and fit multi-env deployment sequencing [Confirmed]
	- External broker/CD dependencies may affect deployment lead time [Inferred]
- Risk acceptance authority and process reference:
	- Not documented in repo; needs team-specific governance owner and approval process [Confirmed-as-unknown]

## Gaps To Resolve

The following fields are required for high-confidence vulnerability exposure scoring and remain unknown:

1. Production ingress architecture and network controls (for example WAF/API gateway/load balancer)
2. Data sensitivity and privacy classification
3. Named service owner and risk acceptance authority

## Analyst Guidance

When analyzing CVEs:

1. Use this file to score Exposure and Criticality.
2. Do not assume all environments have the same exposure; use the environment-specific details documented above.
3. Score production and development/test separately when exposure differs.
4. Distinguish external exposure from internal lateral movement risk.
