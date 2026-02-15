# Home Assistant Update Procedure for AI Agents

## ⚠️ CRITICAL RULE
**Read release notes for EVERY component being updated, regardless of type (core, integration, custom component, container, etc.). Check for incompatibilities and breaking changes.**

## Update Analysis Workflow

### Phase 1: Version Discovery & Dependency Mapping

1. **Identify all components with versions:**
   - Home Assistant core (`Dockerfile` line 1)
   - ESPHome (`docker-compose.yml`)
   - All custom components (`Dockerfile` ENV section)
   - All custom cards (`Dockerfile` ENV section)

2. **Find latest stable patch versions:**
   - Use GitHub API for releases
   - Verify availability in Docker registries (ghcr.io, Docker Hub)
   - Always prefer X.Y.Z over X.Y.0 (patches exist for a reason)

3. **Map version dependencies:**
   - Check if component updates REQUIRE specific HA versions
   - Check if component updates FORCE updates of other components
   - Document the dependency chain

### Phase 2: Breaking Changes Analysis

**For EACH version being updated:**

1. **If skipping intermediate versions:**
   - Read ALL release notes from current → target version
   - Example: 2025.7.4 → 2025.9.4 requires reading 2025.8.x AND 2025.9.x notes

2. **Extract breaking changes:**
   - Integration removals/deprecations
   - Service call changes (renamed, removed, new parameters)
   - Entity state value changes
   - Configuration format changes
   - Required actions (re-pairing devices, migrations)

3. **Check version compatibility requirements:**
   - "Requires Home Assistant X.Y.Z+" flags
   - Platform/framework version requirements
   - Dependency version constraints

### Phase 3: Configuration Impact Assessment

**Scan user's entire HA configuration** for affected patterns:

```python
# Pseudo-code for systematic checking:
for breaking_change in all_breaking_changes:
    if breaking_change.type == "integration_removed":
        search_config_for(breaking_change.integration_name)
    
    elif breaking_change.type == "service_renamed":
        search_config_for(breaking_change.old_service_name)
    
    elif breaking_change.type == "state_value_changed":
        search_config_for(breaking_change.old_state_value)
    
    elif breaking_change.type == "config_format_changed":
        search_config_for(breaking_change.integration_name)
        analyze_config_structure()
```

**Search locations:**
- `config/packages/*/` (all subdirectories and files)
- `config/__auto_generated-config/*/` (generated configs)
- `config/configuration.yaml` (main config)
- `config/automations.yaml`, `config/scripts.yaml`, etc.

**Search patterns:**
- Integration/platform names
- Service call names (domain.service format)
- State values used in conditions/templates
- Configuration keys being deprecated

### Phase 4: Compatibility Matrix

Build a table to verify:

| Component | Current | Target | HA Version Required | Breaking Changes | User Affected | Action |
|-----------|---------|--------|---------------------|------------------|---------------|--------|
| HA Core | X.Y.Z | A.B.C | - | List specifics | Yes/No | Config changes needed |
| Component N | ... | ... | Check release notes | List specifics | Yes/No | Document action |

**Verification rules:**
- ✅ No component requires HA version > target HA version
- ✅ All breaking changes either don't affect user OR have documented fixes
- ✅ All forced dependency updates are included

### Phase 5: Generate Update Plan

**Files to modify:**
1. `home_automation/home_assistant/Dockerfile` - HA version + component versions
2. `home_automation/docker-compose.yml` - ESPHome and other service versions

**Configuration fixes (if needed):**
- Document exact file paths and changes required
- Provide before/after examples
- Note if automated fix is possible vs manual review needed

**Post-update actions:**
- List any devices that need re-pairing
- List any manual verification steps
- Warning about potential issues to monitor

## Example Compatibility Failure Pattern

```yaml
# This scenario would FAIL verification:
Target HA: 2025.9.4
Component X: v2.6.1 (release notes say "Requires HA 2025.10+")
❌ INCOMPATIBLE - must downgrade to v2.5.3 or upgrade HA to 2025.10+
```

## Output Format for User

Provide:
1. **Version Update Summary Table** - clear, scannable
2. **Breaking Changes Impact** - only what affects user
3. **Required Actions** - specific, actionable items
4. **Risk Assessment** - what could break, monitoring needed
5. **Deployment Commands** - backup, build, deploy, verify

## Quality Checklist

Before presenting update plan:
- [ ] ALL release notes reviewed (core + all components)
- [ ] ALL intermediate versions checked (if skipping versions)
- [ ] Version compatibility matrix validated (no conflicts)
- [ ] User's config scanned for ALL breaking change patterns
- [ ] Latest PATCH versions confirmed (not just minor versions)
- [ ] Post-update actions documented
- [ ] User-specific impacts identified (not generic warnings)

## Key Insights

- **Version numbers don't tell compatibility** - must read release text
- **Higher version ≠ better** - may require dependencies user can't meet
- **Absence of evidence ≠ evidence of absence** - always verify, don't assume
- **Patch versions matter** - they contain critical fixes
- **Configuration is a web** - one breaking change can cascade through automations
