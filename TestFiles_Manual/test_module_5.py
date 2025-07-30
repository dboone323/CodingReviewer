"""
test_module_5.py
Manual Test Python Module 5
"""

import asyncio
import json
from datetime import datetime
from typing import List, Dict, Optional

class TestProcessor5:
    def __init__(self, name: str = "TestProcessor5"):
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
    processor = TestProcessor5()
    
    # Add test data
    for j in range(5):
        processor.add_data({
            "test_value": f"Value {j} from module 5",
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
