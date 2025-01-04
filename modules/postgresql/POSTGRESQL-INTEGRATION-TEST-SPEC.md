# PostgreSQL Integration Test Specification

## AI Agent Rules
1. Follow incremental testing approach - test basic PostgreSQL first, then add Immich, then Open WebUI
2. Keep test cases focused and specific to each component
3. Maintain clear separation between test stages
4. Do not modify existing module code unless absolutely necessary
5. Ensure proper cleanup in test teardown

## 1. Project Details
- **Module**: PostgreSQL Integration Test
- **Dependencies**: 
  - modules/postgresql/
  - modules/immich/
  - modules/open-webui/
- **Test Type**: NixOS Integration Test
- **Location**: tests/postgresql-integration.nix

## 2. End Goal
Create a comprehensive NixOS test that verifies:
1. Basic PostgreSQL functionality with clubcotton module
2. Immich database integration and extensions
3. Open WebUI database integration
4. All components working together correctly

## 3. Current Implementation Details
```
modules/postgresql/
├── default.nix         # Main PostgreSQL module
├── immich.nix         # Immich database support
├── open-webui.nix     # Open WebUI database support
└── test.nix           # Current basic test
```

- **default.nix**: Core PostgreSQL module with basic configuration options
- **immich.nix**: Immich-specific database setup and extensions
- **open-webui.nix**: Open WebUI database configuration
- **test.nix**: Current test file testing all components together

## 4. Updated Implementation Details
New test structure:
```
tests/
└── postgresql-integration.nix   # New comprehensive test file
```

## 5. Current Proposed Solution
1. Create new test file focusing on incremental testing
2. Test components in isolation first
3. Combine components in final integration test
4. Verify all features and interactions

## 6. Next Steps
1. ✅ Basic PostgreSQL test:
   - Test service startup
   - Verify port configuration
   - Check data directory creation
   - Test basic authentication

2. ✅ Immich database testing:
   - Verify test implementation:
     - Database creation
     - User creation and permissions
     - Required extensions
     - Schema ownership
   - Run and debug tests
   - Document any issues found

3. ✅ Add Open WebUI database testing:
   - Test database creation
   - Verify user creation
   - Check schema ownership
   - Test basic operations

4. ✅ Integration testing:
   - Test all components running together
   - Verify no conflicts
   - Check resource usage
   - Ensure proper cleanup

## 7. Current Unresolved Issues
None - all test implementations have been verified and are working correctly.

## 8. Change Log
- Initial spec creation
- Added initial test implementation for PostgreSQL and Immich (needs verification)
- Added Open WebUI database support:
  - Added passwordFile option to open-webui.nix
  - Added password setting logic in postStart service
  - Added Open WebUI node configuration and database tests