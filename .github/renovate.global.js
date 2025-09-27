// File: .github/renovate.global.js
// This file contains the GLOBAL configuration for the Renovate bot.
// It is referenced by the `configurationFile` input in the GitHub Actions workflow.
// These settings can ONLY be configured at the global level for security and operational reasons.

module.exports = {
  // The 'platform' option is required at the global level.
  // It tells Renovate which source code management platform to use.
  platform: 'github',

  // 'onboarding' controls whether Renovate creates an initial "Configure Renovate" PR
  // for new repositories. We disable it since we manage configuration centrally.
  onboarding: false,

  // The 'repositories' array tells Renovate which repositories to process.
  // Explicitly defined to prevent processing of forked repositories.
  repositories: [
    'ManuelLR/MomaHome'
  ],

  // 'forkProcessing' controls how Renovate handles forked repositories.
  // Disabled to prevent any fork of this repo from being processed.
  forkProcessing: 'disabled',

  // WARNING: 'allowPlugins' is a security-sensitive setting that allows
  // package managers to execute arbitrary code via plugins.
  // Enable only if you fully trust all dependencies and their plugins.
  allowPlugins: true,

  // 'globalExtends' applies mandatory, organization-wide presets that
  // individual repositories cannot ignore or override.
  // These are enforced policies, not suggestions.
  globalExtends: [
    'config:recommended',
    ':dependencyDashboard',
    ':rebaseStalePrs',
    ':semanticCommits',
    ':semanticCommitScope(deps)',
    'mergeConfidence:all-badges'
  ],

  // 'printConfig' outputs the full resolved config for debugging purposes
  printConfig: true,

  // 'prHourlyLimit' controls the rate of PR creation (0 = unlimited)
  prHourlyLimit: 0,

  // 'useBaseBranchConfig' determines how configs from different branches are handled
  // 'merge' allows testing configuration changes before merging to the base branch
  // by merging the base branch config with the current branch config
  useBaseBranchConfig: 'merge'
};
