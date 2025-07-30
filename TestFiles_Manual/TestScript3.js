/**
 * TestScript3.js
 * Manual Test JavaScript File 3
 */

class TestManager3 {
    constructor() {
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: 'TestManager3'
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: 'TestScript3'
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager3: ${item}`);
            }
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: 'TestScript3'
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
const manager3 = new TestManager3();
manager3.addItem('Test item from script 3');
manager3.addItem('Another test item');

const stats = manager3.getStatistics();
console.log('Statistics for TestScript3:', stats);
