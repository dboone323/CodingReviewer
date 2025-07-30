/**
 * TestScript4.js
 * Manual Test JavaScript File 4
 */

class TestManager4 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager4'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript4'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager4: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript4'
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
const manager4 = new TestManager4();
manager4.addItem('Test item from script 4');
manager4.addItem('Another test item');

const stats = manager4.getStatistics();
console.log('Statistics for TestScript4:', stats);
