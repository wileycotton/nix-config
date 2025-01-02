# ZFS RAIDZ1 Test Implementation Spec

## Rules for AI Agent
1. Do not change the structure or delete sections from this markdown spec
2. Favor simple solutions over complex ones
3. Make decisions that benefit project longevity without over-abstracting
4. Create commits for each step with detailed reasoning
5. Start with empty commit containing request and end with cost/stats commit

## Project Details
- Location: modules/zfs/
- Key Files:
  - zfs-raidz1.nix: Main RAIDZ1 module implementation
  - zfs-single-root.nix: Single root module implementation
  - lib.nix: Library functions for ZFS configurations
  - zfs-raidz1-test.nix: To be created

## End Goal
Create a test suite that combines a single-disk root filesystem with an additional RAIDZ1 pool, verifying both configurations work together correctly.

## Current Implementation Details
### File Tree
```
modules/zfs/
├── common.nix
├── lib.nix
├── zfs-raidz1.nix
├── zfs-single-root.nix
└── zfs-single-root-test.nix
```

### Description of Files
- common.nix: Contains common ZFS configuration options
- lib.nix: Library functions for ZFS configurations
- zfs-raidz1.nix: RAIDZ1 module implementation
- zfs-single-root.nix: Single root module implementation
- zfs-single-root-test.nix: Test implementation for single root configuration

## Updated Implementation Details
### New/Modified Files
```
modules/zfs/
├── common.nix
├── lib.nix (modified)
├── zfs-raidz1.nix
├── zfs-raidz1-test.nix (new)
├── zfs-single-root.nix
└── zfs-single-root-test.nix
```

## Current Proposed Solution
1. Create a test that combines:
   - Root filesystem using zfs-single-root module on /dev/vda
   - Additional RAIDZ1 pool using 4 disks (/dev/vdb through /dev/vde)
2. Reuse existing makeZfsSingleRootConfig for root filesystem
3. Add makeZfsRaidz1Config for the additional pool

## Next Steps
1. Add makeZfsRaidz1Config to lib.nix:
   - Function should accept poolname and list of disks
   - Configure RAIDZ1 pool without boot or root filesystem requirements
   - Support dataset configuration for the additional pool

2. Create zfs-raidz1-test.nix:
   - Use makeZfsSingleRootConfig for root filesystem on /dev/vda
   - Use makeZfsRaidz1Config for additional pool on /dev/vdb through /dev/vde
   - Configure both pools in the same test
   - Set up test datasets on the RAIDZ1 pool

3. Implement test cases:
   - Verify root filesystem works as in single-root test
   - Additional tests for RAIDZ1 pool:
     - Pool health and RAIDZ1 properties
     - Dataset creation and properties
     - Mountpoint verification
     - Pool redundancy verification

4. Test Configuration:
   - Root pool: "zroot" on /dev/vda
   - RAIDZ1 pool: "tank" on /dev/vdb through /dev/vde
   - Example datasets on RAIDZ1 pool:
     - tank/data
     - tank/backup

## Current Unresolved Issues
1. Need to verify if any special considerations are needed for running two pools simultaneously
2. Need to determine optimal test dataset configuration for RAIDZ1 pool

## Change Log
- Initial spec creation with outline of dual-pool test implementation
- Updated spec based on feedback to use single-root module for root filesystem and separate RAIDZ1 pool
- Implemented makeZfsRaidz1Config in lib.nix with proper poolname parameterization
- Created zfs-raidz1-test.nix with:
  - Root filesystem configuration using makeZfsSingleRootConfig
  - RAIDZ1 pool configuration using makeZfsRaidz1Config
  - Comprehensive test suite for both pools
  - RAIDZ1-specific resilience tests using disk offline/online operations
  - Dataset property verification for both pools
  - Mountpoint and boot configuration tests
