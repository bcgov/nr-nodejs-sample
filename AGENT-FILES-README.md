# Agent Files Summary - NestJS Security Patch Analysis

This document explains the agent files created for the nr-nodejs-sample repository to enable automated security patch analysis aligned with BC Government OCIO patching guidelines.

## Files Created

### 1. `.instructions.md`
**Purpose**: Foundational project documentation for agents  
**Contains**:
- Project overview and architecture
- Technology stack details
- Dependency management process
- OCIO patching timelines (72h/14d/30d/1y)
- Development workflows and commands
- Security patching guidelines
- CI/CD pipeline integration
- Testing requirements

**Used By**: All agents; loaded automatically as context  
**Key Sections**: 
- Agent Responsibilities (how to approach patching)
- Security Patching Guidelines table
- Testing Requirements
- Artifact Publishing details

---

### 2. `.agent.md`
**Purpose**: Agent-specific configuration and responsibilities  
**Contains**:
- YAML frontmatter defining agent type (nodejs, nestjs)
- Vulnerability discovery process
- Severity classification per OCIO framework
- Patch analysis methodology
- Testing strategy for patches
- Patch implementation workflow
- Risk assessment procedures
- Deployment process
- Success criteria for patch analysis

**Key Workflow**:
1. Run `npm audit` and parse results
2. Map CVSS scores to OCIO timelines
3. Identify production vs. dev dependencies
4. Assess breaking changes
5. Test with full suite (unit, E2E, lint, build)
6. Validate no new vulnerabilities
7. Commit with CVE references
8. Deploy via CI/CD

**Success Criteria**: ✅ All test suites passing, ✅ CVE documented, ✅ OCIO deadline identified

---

### 3. `.prompt.md`
**Purpose**: Prompt templates and examples for agents  
**Contains**:
- 5 main patch analysis prompts (scan, compatibility, risk, execution, dependency tree)
- 3 detailed example scenarios (CRITICAL, HIGH, MEDIUM patches)
- Troubleshooting prompts
- Validation checklist template
- Emergency patch response template

**Used For**: 
- Giving agents structured tasks to execute
- Providing examples of expected output format
- Guiding agents through complex workflows
- Troubleshooting when patches fail

**Example Prompts**:
- "Analyze the nr-nodejs-sample project for security vulnerabilities"
- "Execute the complete patching workflow for CVE-XXXX-XXXXX"
- "Assess the patch application timeline and risk"

---

### 4. `copilot-instructions.md`
**Purpose**: GitHub Copilot-specific guidance  
**Contains**:
- NestJS code patterns and examples
- Security-focused DO's and DON'Ts
- Patch analysis workflow (4 steps)
- Common scenarios with recommendations
- Key files reference table
- Copilot collaboration tips
- Performance timelines

**Used By**: GitHub Copilot Chat  
**Key Tips**:
- Provide context about internet-facing API
- Ask Copilot to analyze npm audit output
- Request validation of patches before recommending
- Ask for commit message drafting

---

### 5. `.github/workflows/security-patch-analysis.yaml`
**Purpose**: Automated security vulnerability scanning and reporting  
**Triggers**:
- Weekly schedule (Tuesday 09:00 UTC)
- Manual dispatch via GitHub UI
- On `package.json` or `package-lock.json` changes
- On push to main branch

**Outputs**:
- Parses `npm audit` results
- Classifies vulnerabilities by OCIO severity (CRITICAL/HIGH/MEDIUM/LOW)
- Calculates patch deadlines
- Creates GitHub Issues for CRITICAL and HIGH vulnerabilities
- Uploads vulnerability report artifact
- Generates markdown report with OCIO compliance details

**Actions Performed**:
1. Checks out code
2. Sets up Node.js 24
3. Installs dependencies
4. Runs `npm audit --json`
5. Parses results and categorizes by CVSS
6. Calculates deadlines (72h/14d/30d/1y)
7. Creates GitHub Issues for urgent patches
8. Uploads report artifacts

**Artifacts Generated**:
- `audit-results.json` - Raw npm audit output
- `vulnerability-report.md` - OCIO-formatted report

---

## How Agents Use These Files

### Workflow: Complete Patch Analysis

**Step 1: Agent Initialization**
```
Agent reads: .instructions.md (project context) + .agent.md (role definition)
Agent understands: Framework, OCIO requirements, testing process
```

**Step 2: Execute Analysis**
```
Agent uses: .prompt.md template "Initial Vulnerability Scan"
Executes: npm audit, parses results, classifies by OCIO
Output: List of CVEs with CVSS, timeline, affected packages
```

**Step 3: Plan Patch**
```
Agent uses: .prompt.md template "Patch Compatibility Check"
Tests: npm install, npm test, npm run test:cov, npm run test:e2e
Output: Patch recommendation or blocker reason
```

**Step 4: Validate Compliance**
```
Agent uses: .prompt.md validation checklist
Verifies: Tests pass, CVE fixed, no new vulns, breaking changes documented
Output: READY_TO_MERGE or BLOCKED status
```

**Step 5: Document & Commit**
```
Agent uses: .prompt.md commit message template
Creates: Git commit with CVE ID, CVSS, OCIO timeline
```

---

## Key Features

### 🔒 OCIO Compliance
- ✅ Timelines enforced: 72h (CRITICAL), 14d (HIGH), 30d (MEDIUM), 1y (LOW)
- ✅ Risk acceptance documentation required for missed deadlines
- ✅ Internet-facing exposure must be confirmed from repository context; this sample repo is currently documented as VPN-only/internal
- ✅ Compensating controls do NOT excuse patching

### 🧪 Comprehensive Testing
- ✅ Unit tests must pass (`npm test`)
- ✅ Coverage must be maintained (`npm run test:cov`)
- ✅ E2E tests must pass (`npm run test:e2e`)
- ✅ Linting must pass (`npm run lint`)
- ✅ Build must succeed (`npm run build`)
- ✅ No new vulnerabilities after patch

### 📊 Automated Reporting
- ✅ Weekly vulnerability scans
- ✅ GitHub Issues created for urgent patches
- ✅ Structured markdown reports
- ✅ Artifacts retained for 90 days
- ✅ OCIO deadline calculations

### 🤖 Agent-Ready
- ✅ Clear workflow documentation
- ✅ Prompt templates for structured execution
- ✅ Success criteria defined
- ✅ Troubleshooting guidance included
- ✅ Code examples provided

---

## Using These Files in Your Workflow

### For Developers
1. Read `.instructions.md` to understand project structure and patch process
2. Use `.prompt.md` examples when asking for patch recommendations
3. Follow the testing requirements before committing patches
4. Reference `.agent.md` for OCIO compliance requirements

### For Agents/Copilot
1. Load `.agent.md` for role definition and responsibilities
2. Use `.prompt.md` templates for structured patch analysis
3. Reference `.instructions.md` for project-specific details
4. Follow success criteria in `.agent.md` for quality gates

### For Automation
1. `.github/workflows/security-patch-analysis.yaml` runs automatically
2. Generates GitHub Issues for urgent patches
3. Uploads artifacts for manual review if needed
4. Integrates with GitHub Projects for tracking

---

## Next Steps

1. **Test the Workflow**: Trigger security-patch-analysis manually in GitHub Actions
2. **Review Results**: Check generated vulnerability report
3. **Create Test Patch**: Use `.prompt.md` template to patch a MEDIUM vulnerability
4. **Validate Process**: Confirm tests pass and commit is properly documented
5. **Enable Automation**: Ensure workflow is scheduled for weekly runs

---

## Files Location Reference

```
nr-nodejs-sample/
├── .instructions.md                           # Project documentation for agents
├── .agent.md                                  # Agent configuration & responsibilities
├── .prompt.md                                 # Prompt templates & examples
├── copilot-instructions.md                    # Copilot-specific guidance
├── .github/workflows/
│   ├── security-patch-analysis.yaml          # OCIO compliance scanner
│   ├── test.yaml                             # Unit & E2E tests
│   └── deploy-nodejs-sample.yaml             # Deployment pipeline
├── package.json                              # Dependency declarations
├── package-lock.json                         # Locked dependency tree
└── src/
    ├── main.ts                               # NestJS bootstrap
    └── ...
```

---

## Support & References

- **OCIO Guidelines**: https://www2.gov.bc.ca/assets/gov/british-columbians-our-governments/services-policies-for-government/information-management-technology/information-security/defensible-security/ocio_patch_guidelines_-_2021-02-18.pdf
- **npm audit**: https://docs.npmjs.com/cli/v10/commands/npm-audit
- **NestJS**: https://nestjs.com
- **GitHub Actions**: https://github.com/features/actions

---

**Document Created**: 2026-06-19  
**Framework**: NestJS 11.x / Node.js 24  
**Compliance**: BC Government OCIO (Feb 2021)
