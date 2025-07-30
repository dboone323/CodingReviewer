/**
 * TestScript8.js
 * Manual Test JavaScript File 8
 */

class TestManager8 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager8'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript8'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager8: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript8'
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
const manager8 = new TestManager8();
manager8.addItem('Test item from script 8');
manager8.addItem('Another test item');

const stats = manager8.getStatistics();
console.log('Statistics for TestScript8:', stats);
