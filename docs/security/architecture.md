# Security Architecture

This file documents system design, data flow, and trust boundaries used to assess vulnerability exposure.

## Metadata

- Last updated: 2026-06-19 [Confirmed]
- Updated by: Copilot bootstrap from repository evidence [Inferred]

## High-Level Components

- Client(s): Unknown from repo (could be API consumers/internal callers) [Confirmed-as-unknown]
- API/service components: NestJS Node.js service (`src/main.ts`, module/controller/service pattern) [Confirmed]
- Data stores: No direct datastore integration evidenced in current source/workflow metadata [Confirmed-as-unknown]
- External dependencies:
	- npm ecosystem dependencies (NestJS, axios, rxjs) [Confirmed]
	- GitHub Packages/ghcr OCI artifact registry [Confirmed]
	- Broker API (`broker.io.nrs.gov.bc.ca`) and CD endpoint (`cd.io.nrs.gov.bc.ca`) for pipeline orchestration [Confirmed]
- Shared platform services: Polaris pipeline, GitHub Actions, Broker intention service [Confirmed]

## Data Flow Summary

Describe major request/response and data movement paths:

1. Source commit/PR/tag triggers GitHub Actions pipeline -> tests/build execute -> OCI artifact is published to ghcr [Confirmed]
2. Build/deploy workflows query Broker API for intention/build metadata and package details [Confirmed]
3. Deployment workflow promotes release through development -> test -> production environments [Confirmed]
4. Runtime request/data flows for application endpoints are not documented in repository [Confirmed-as-unknown]

## Trust Boundaries

Define explicit trust transitions:

- Internet -> perimeter controls: Not reachable; public internet access is not used for the runtime path [Confirmed]
- VPN/internal network -> application: Required access path for runtime users [Confirmed]
- Application -> internal services: Unknown at runtime; CI/CD path integrates with broker/cd APIs [Confirmed + Inferred]
- Application -> data store: Not documented [Confirmed-as-unknown]
- Cross-cluster or cross-network boundaries:
	- GitHub-hosted runners crossing to BCGov broker/cd endpoints [Inferred]
	- Promotion across multiple deployment environments [Confirmed]

## Authentication and Authorization

- Identity provider/auth mechanism:
	- CI/CD uses `GITHUB_TOKEN` and broker JWT secrets [Confirmed]
	- Runtime application authentication is not required; VPN access provides the runtime network boundary [Confirmed]
- Service-to-service auth:
	- Broker API calls use bearer/JWT secrets in workflows [Confirmed]
	- Runtime service-to-service auth unknown [Confirmed-as-unknown]
- Privileged operations and boundaries:
	- Package publishing to ghcr and deployment submission are privileged CI actions [Confirmed]

## Network Controls

- Ingress controls: VPN-restricted internal access [Confirmed]
- Egress controls: CI workflows egress to GitHub API, Broker API, cd endpoint, ghcr [Confirmed]
- Segmentation/micro-segmentation: Not documented [Confirmed-as-unknown]
- Internal access restrictions: VPN required [Confirmed]

## Observability and Detection

- Security logging:
	- CI logs include build/test/deploy metadata and broker interaction outcomes [Confirmed]
- Alerting and monitoring:
	- Dependabot security alerts in GitHub Security and quality view [Confirmed from team statement]
	- No runtime SOC/SIEM integration documented in repo [Confirmed-as-unknown]
- Runtime detection controls: Not documented [Confirmed-as-unknown]

## Evidence References

1. `catalog-info.yaml`
2. `.github/workflows/build-release-nodejs-sample.yaml`
3. `.github/workflows/deploy-nodejs-sample.yaml`
4. `.github/workflows/run-deploy-nodejs-sample.yaml`
5. `.github/workflows/test.yaml`
6. `package.json`

## Analyst Guidance

Use this file to score Exposure in vulnerability analysis:

- External reachability
- Internal lateral movement potential
- Boundary crossing required by exploit path
