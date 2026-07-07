# Threat Model

This file records known risks, assumptions, and security-relevant scenarios for vulnerability context.

## Metadata

- Last updated: 2026-06-19 [Confirmed]
- Updated by: Copilot bootstrap from repository evidence [Inferred]

## Scope

- In-scope components:
	- Node.js/NestJS application code and npm dependencies [Confirmed]
	- Build/test/deploy GitHub Actions workflows [Confirmed]
	- Artifact publication flow to ghcr and broker metadata exchange [Confirmed]
- Out-of-scope components:
	- Downstream runtime infrastructure specifics (cluster topology, ingress, WAF) not documented in repo [Confirmed-as-unknown]
	- Organization-wide IAM policies and SOC tooling not documented in repo [Confirmed-as-unknown]

## Assumptions

- Network assumptions:
	- Service is reachable only through VPN-connected internal access paths and is not internet-exposed [Confirmed]
	- CI runners communicate with external APIs (GitHub, broker, cd, ghcr) [Confirmed]
- Identity and access assumptions:
	- Secrets (`GITHUB_TOKEN`, broker JWT) are managed via GitHub Actions secret store [Confirmed]
	- Least privilege is intended but role bindings are not visible here [Inferred]
- Data handling assumptions:
	- No explicit sensitive data classification documented [Confirmed-as-unknown]
	- Treat as unknown sensitivity until owner confirms classification [Inferred]
- Operational assumptions:
	- Patching/deployments must traverse dev/test/prod promotion path [Confirmed]
	- Dependabot alerts are monitored by team [Confirmed from team statement]

## Known Threat Scenarios

For each scenario, include attacker type, preconditions, impact, and controls.

### Scenario 1

- Threat description: Exploitation of vulnerable npm dependency (for example RCE/SSRF class) in application runtime.
- Attacker type: Internal actor or VPN-connected user with network path [Confirmed]
- Preconditions:
	- Vulnerable package present in dependency tree [Confirmed in general process]
	- Reachability to vulnerable code path [Unknown]
- Potential impact:
	- Remote code execution, service compromise, or data exposure depending on affected package [Inferred]
- Existing controls:
	- Dependabot alerting [Confirmed from team statement]
	- CI tests and build gating before release [Confirmed]
- Residual risk: Medium while data sensitivity remains unverified, even though runtime exposure is confirmed as VPN-only [Inferred]

### Scenario 2

- Threat description: Supply-chain or CI/CD abuse via compromised token/secret or malicious dependency update.
- Attacker type: External attacker targeting CI secrets or package supply chain [Inferred]
- Preconditions:
	- Access to token/secrets or successful dependency poisoning [Inferred]
	- Ability to trigger pipeline path [Inferred]
- Potential impact:
	- Publishing malicious artifacts, deployment of compromised build, downstream environment impact [Inferred]
- Existing controls:
	- Workflow checks, mergeability checks, staged promotion flow [Confirmed]
	- Tokenized broker intention model in build/deploy [Confirmed]
- Residual risk: Medium due to high impact potential despite CI controls [Inferred]

## Vulnerability-Relevant Notes

- Components with historically higher vulnerability exposure:
	- HTTP-facing libraries/framework packages (`@nestjs/*`, `axios`, transitive packages) [Inferred]
	- CI workflow logic using privileged tokens [Inferred]
- Third-party dependencies with elevated risk posture:
	- Large transitive npm dependency graph typical of Node.js services [Inferred]
	- Supply-chain exposure via external registries and artifact publication endpoints [Confirmed + Inferred]
- Typical exploit paths:
	- External: not applicable for runtime exposure because the service is not internet-exposed [Confirmed]
	- Internal: exploit from VPN-connected internal network segment or compromised CI pipeline [Inferred]

## Incident and Mitigation History

- Relevant prior security incidents: None documented in repository [Confirmed-as-unknown]
- Effective mitigations observed:
	- CI testing and staged deployment progression [Confirmed]
	- Dependabot advisory visibility [Confirmed from team statement]
- Outstanding gaps:
	- No documented data sensitivity classification [Confirmed]
	- No documented risk acceptance owner/process in repo [Confirmed]

## Initial Confidence Level

- Overall confidence in this initial threat model: Medium-Low
- Reason: CI/CD and dependency evidence are strong, but runtime exposure/data criticality evidence is incomplete.

## Evidence References

1. `catalog-info.yaml`
2. `.github/workflows/build-release-nodejs-sample.yaml`
3. `.github/workflows/deploy-nodejs-sample.yaml`
4. `.github/workflows/run-deploy-nodejs-sample.yaml`
5. `.github/workflows/test.yaml`
6. `package.json`

## Analyst Guidance

Use this file to calibrate Exploitability and Criticality scoring:

- Exploit realism in this environment
- Business impact if exploit succeeds
- Effectiveness of existing mitigations
