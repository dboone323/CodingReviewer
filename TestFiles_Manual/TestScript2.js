/**
 * TestScript2.js
 * Manual Test JavaScript File 2
 */

class TestManager2 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager2'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript2'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager2: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript2'
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
const manager2 = new TestManager2();
manager2.addItem('Test item from script 2');
manager2.addItem('Another test item');

const stats = manager2.getStatistics();
console.log('Statistics for TestScript2:', stats);
