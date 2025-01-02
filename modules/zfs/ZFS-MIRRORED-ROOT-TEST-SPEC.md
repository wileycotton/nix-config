# ZFS Mirrored Root Test Specification

## Rules for AI Agent
1. Follow the same patterns used in zfs-single-root-test.nix
2. Keep solutions simple and avoid over-complication
3. Create commits for each step with detailed reasoning
4. Do not modify existing functionality, only refactor to support test cases
5. Ensure all test cases validate the mirrored setup properly
6. Update both Atlas tasks and this SPEC file as implementation progresses

## Project Details
This specification outlines the refactoring of the ZFS mirrored root configuration to support test cases. The goal is to follow the same patterns used in the single root test implementation while ensuring proper validation of mirrored setups.

Atlas Task ID: task_1735853270483_nrv5n2w4k

## End Goal
Create a test module for the ZFS mirrored root configuration that validates:
- Proper mirror setup
- Multiple boot partitions
- Encrypted swap on both disks
- ZFS pool and dataset configuration
- Boot loader configuration
- Mountpoints and filesystem properties

## Current Implementation Details

### File Tree
```
modules/zfs/
├── common.nix
├── lib.nix
├── zfs-mirrored-root.nix
└── zfs-single-root-test.nix
```

### File Descriptions
- common.nix: Common ZFS configuration options
- lib.nix: Library functions for ZFS configuration
- zfs-mirrored-root.nix: Main mirrored root implementation
- zfs-single-root-test.nix: Test implementation for single root setup

## Updated Implementation Details
Will add:
```
modules/zfs/
├── ...existing files...
└── zfs-mirrored-root-test.nix
```

## Current Proposed Solution

1. Create a new library function in lib.nix: makeZfsMirroredRootConfig
2. Create zfs-mirrored-root-test.nix following single root test patterns
3. Implement test cases specific to mirrored setup validation

### Key Components:
1. Library Function:
   - Convert existing mirrored root config to a reusable function
   - Support test-specific parameters
   - Handle multiple disk configurations

2. Test Module:
   - Use makeDiskoTest from disko library
   - Configure multiple virtual disks
   - Implement mirror-specific test cases

3. Test Cases:
   - Mirror status and health
   - Multiple boot partition validation
   - Encrypted swap on all disks
   - ZFS pool and dataset properties
   - Boot loader configuration

## Next Steps

1. ✓ Add makeZfsMirroredRootConfig to lib.nix:
   - ✓ Extract configuration logic from zfs-mirrored-root.nix
   - ✓ Create function with parameters for disks, pool name, swap size, and filesystems
   - ✓ Ensure compatibility with test environment
   - ✓ Update Atlas task status upon completion

2. ✓ Create zfs-mirrored-root-test.nix:
   - ✓ Use makeDiskoTest framework
   - ✓ Configure multiple virtual disks
   - ✓ Set up test configuration using new library function
   - ✓ Implement test assertions
   - ✓ Update Atlas task status upon completion

3. ✓ Test and validate:
   - ✓ Run test cases
   - ✓ Verify mirror functionality
   - ✓ Ensure all assertions pass
   - ✓ Update Atlas milestone status upon completion

## Current Unresolved Issues
None - all planned functionality has been implemented and tested.

## Change Log
- Initial specification created with Atlas task tracking integration (task_1735853270483_nrv5n2w4k)
- Added makeZfsMirroredRootConfig function to lib.nix (task_1735853319276_omuxk3mac)
  * Implemented mirror-specific disk configuration
  * Added support for multiple boot partitions
  * Added encrypted swap configuration
  * Configured ZFS pool in mirror mode
- Created zfs-mirrored-root-test.nix test module (task_1735853452143_fxwqdtryv)
  * Implemented basic mirror configuration tests
  * Added tests for boot partitions on both disks
  * Added swap device verification
  * Verified ZFS properties and dataset structure
