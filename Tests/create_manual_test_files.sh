#!/bin/bash

# Manual Test Script for CodingReviewer
# This script creates test files to verify the app functionality

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
TEST_FILES_DIR="$PROJECT_PATH/TestFiles_Manual"

echo -e "${BLUE}🧪 Creating Manual Test Files for CodingReviewer${NC}"
echo "=============================================="

# Create test files directory
echo -e "${YELLOW}📁 Creating test files directory...${NC}"
mkdir -p "$TEST_FILES_DIR"

# Create Swift test files
echo -e "${YELLOW}📝 Creating Swift test files...${NC}"
for i in {1..20}; do
    cat > "$TEST_FILES_DIR/TestFile$i.swift" << EOF
//
//  TestFile$i.swift
//  Manual Test File $i
//

import Foundation
import SwiftUI

class TestClass$i: ObservableObject {
    @Published var data: [String] = []
    
    func loadData() {
        data = Array(1...10).map { "Item \$0 from TestFile$i" }
    }
    
    func processData() {
        print("Processing data in TestFile$i")
        for item in data {
            print("  - \(item)")
        }
    }
    
    func complexMethod(param1: String, param2: Int) -> String {
        if param2 > 5 {
            return "Complex result from \(param1) with value \(param2)"
        } else {
            return "Simple result from \(param1)"
        }
    }
}

struct TestView$i: View {
    @StateObject private var testClass = TestClass$i()
    
    var body: some View {
        VStack {
            Text("Test View $i")
                .font(.title)
            
            Button("Load Data") {
                testClass.loadData()
            }
            
            List(testClass.data, id: \.self) { item in
                Text(item)
            }
        }
        .onAppear {
            testClass.loadData()
        }
    }
}
EOF
done

# Create JavaScript test files
echo -e "${YELLOW}📝 Creating JavaScript test files...${NC}"
for i in {1..15}; do
    cat > "$TEST_FILES_DIR/TestScript$i.js" << EOF
/**
 * TestScript$i.js
 * Manual Test JavaScript File $i
 */

class TestManager$i {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager$i'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript$i'
            });
            
            if (this.config.debug) {
                console.log(\`Added item to TestManager$i: \${item}\`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript$i'
            };
        });
    }
    
    getStatistics() {
        return {
            totalItems: this.items.length,
            manager: this.config.name,
            lastUpdate: new Date().toISOString()
        };
    }
}

// Usage
const manager$i = new TestManager$i();
manager$i.addItem('Test item from script $i');
manager$i.addItem('Another test item');

const stats = manager$i.getStatistics();
console.log('Statistics for TestScript$i:', stats);
EOF
done

# Create Python test files
echo -e "${YELLOW}📝 Creating Python test files...${NC}"
for i in {1..10}; do
    cat > "$TEST_FILES_DIR/test_module_$i.py" << EOF
"""
test_module_$i.py
Manual Test Python Module $i
"""

import asyncio
import json
from datetime import datetime
from typing import List, Dict, Optional

class TestProcessor$i:
    def __init__(self, name: str = "TestProcessor$i"):
        self.name = name
        self.data: List[Dict] = []
        self.config = {
            "max_items": 50,
            "debug": True,
            "processing_mode": "batch"
        }
    
    def add_data(self, item: Dict) -> None:
        """Add a data item to the processor."""
        if len(self.data) < self.config["max_items"]:
            item_with_metadata = {
                **item,
                "id": len(self.data) + 1,
                "timestamp": datetime.now().isoformat(),
                "processor": self.name
            }
            self.data.append(item_with_metadata)
            
            if self.config["debug"]:
                print(f"Added item to {self.name}: {item}")
    
    async def process_data(self) -> List[Dict]:
        """Process all data items asynchronously."""
        print(f"Processing {len(self.data)} items in {self.name}")
        
        processed_items = []
        for item in self.data:
            # Simulate async processing
            await asyncio.sleep(0.01)
            
            processed_item = {
                **item,
                "processed": True,
                "processed_at": datetime.now().isoformat(),
                "processed_by": self.name
            }
            processed_items.append(processed_item)
        
        return processed_items
    
    def get_statistics(self) -> Dict:
        """Get processing statistics."""
        return {
            "processor_name": self.name,
            "total_items": len(self.data),
            "config": self.config,
            "last_update": datetime.now().isoformat()
        }
    
    def export_data(self, filename: Optional[str] = None) -> str:
        """Export data to JSON format."""
        if filename is None:
            filename = f"{self.name}_data.json"
        
        export_data = {
            "metadata": self.get_statistics(),
            "items": self.data
        }
        
        return json.dumps(export_data, indent=2)

# Usage example
async def main():
    processor = TestProcessor$i()
    
    # Add test data
    for j in range(5):
        processor.add_data({
            "test_value": f"Value {j} from module $i",
            "type": "test_data"
        })
    
    # Process data
    processed = await processor.process_data()
    print(f"Processed {len(processed)} items")
    
    # Get statistics
    stats = processor.get_statistics()
    print(f"Statistics: {stats}")

if __name__ == "__main__":
    asyncio.run(main())
EOF
done

# Create configuration files
echo -e "${YELLOW}📝 Creating configuration files...${NC}"
cat > "$TEST_FILES_DIR/test_config.json" << EOF
{
  "test_configuration": {
    "name": "Manual Test Configuration",
    "version": "1.0.0",
    "created": "$(date -Iseconds)",
    "test_files": {
      "swift_files": 20,
      "javascript_files": 15,
      "python_files": 10,
      "total_files": 45
    },
    "test_parameters": {
      "file_upload_limit": 1000,
      "expected_behavior": "All files should upload and be accessible across views",
      "analytics_expected": true,
      "ai_features_expected": true
    },
    "validation_checklist": [
      "Upload all test files to FileUploadView",
      "Verify file count shows 45+ files",
      "Switch to Enhanced AI Insights tab",
      "Confirm uploaded files are visible in analytics",
      "Check ML Integration can access files",
      "Verify real-time updates between views"
    ]
  }
}
EOF

cat > "$TEST_FILES_DIR/README.md" << EOF
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
EOF

echo -e "${GREEN}✅ Manual test files created successfully!${NC}"
echo ""
echo "📁 Location: $TEST_FILES_DIR"
echo "📊 Files created:"
echo "   • 20 Swift files"
echo "   • 15 JavaScript files"  
echo "   • 10 Python files"
echo "   • 1 JSON config file"
echo "   • 1 README file"
echo "   📋 Total: 47 files"
echo ""
echo -e "${BLUE}🧪 Ready for manual testing!${NC}"
echo ""
echo "Next steps:"
echo "1. Open CodingReviewer app"
echo "2. Go to File Upload tab"
echo "3. Select all files from: $TEST_FILES_DIR"
echo "4. Verify upload succeeds (should handle 47 files easily)"
echo "5. Check that files appear in Analytics and AI views"
echo ""
echo -e "${GREEN}🎯 This will verify both issues are fixed:${NC}"
echo "   ✅ File limit increased to 1000"
echo "   ✅ Cross-view data sharing working"
