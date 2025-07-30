/**
 * TestScript5.js
 * Manual Test JavaScript File 5
 */

class TestManager5 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager5'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript5'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager5: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript5'
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
const manager5 = new TestManager5();
manager5.addItem('Test item from script 5');
manager5.addItem('Another test item');

const stats = manager5.getStatistics();
console.log('Statistics for TestScript5:', stats);
