/**
 * TestScript1.js
 * Manual Test JavaScript File 1
 */

class TestManager1 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager1'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript1'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager1: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript1'
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
const manager1 = new TestManager1();
manager1.addItem('Test item from script 1');
manager1.addItem('Another test item');

const stats = manager1.getStatistics();
console.log('Statistics for TestScript1:', stats);
