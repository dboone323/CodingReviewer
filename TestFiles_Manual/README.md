# Manual Test Files for CodingReviewer

This directory contains test files to manually verify the app functionality.

## Test Files Created
- **20 Swift files** (.swift) - Complex SwiftUI components and classes
- **15 JavaScript files** (.js) - ES6 classes and async functions  
- **10 Python files** (.py) - Async processors and data handlers
- **1 JSON config** (.json) - Test configuration
- **Total: 46 files**

## How to Test

### 1. File Upload Limit Test
1. Open CodingReviewer app
2. Go to File Upload tab
3. Select all files in this directory (46 files)
4. ✅ **Expected**: Upload should succeed (limit is now 1000)
5. ❌ **Previous**: Would fail at 100 files

### 2. Cross-View Data Sharing Test
1. After uploading files, note the file count
2. Switch to "Enhanced AI Insights" tab
3. ✅ **Expected**: Should see all 46 uploaded files
4. ❌ **Previous**: Would show 0 files (no data sharing)

### 3. Analytics Integration Test
1. In Analytics view, check file statistics
2. ✅ **Expected**: Should show language breakdown:
   - Swift: 20 files
   - JavaScript: 15 files  
   - Python: 10 files
   - JSON: 1 file
4. ❌ **Previous**: Would show empty or stale data

### 4. Real-time Updates Test
1. Have multiple tabs open (Upload, Analytics, AI Insights)
2. Upload additional files in Upload tab
3. ✅ **Expected**: Other tabs update immediately
4. ❌ **Previous**: Other tabs wouldn't update

## Success Criteria
- [ ] All 46 files upload successfully
- [ ] File count visible across all views
- [ ] Analytics show correct language distribution
- [ ] AI features can access uploaded file data
- [ ] Real-time updates work between views
- [ ] No crashes or performance issues

## File Complexity
Files are designed with varying complexity levels:
- **Simple**: Basic classes and functions
- **Medium**: Multiple methods, some logic
- **Complex**: Async operations, generics, patterns

This tests the app's ability to handle diverse code types and complexity levels.
