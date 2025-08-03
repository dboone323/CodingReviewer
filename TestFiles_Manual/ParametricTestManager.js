/**
 * ParametricTestManager.js
 * Unified Test JavaScript Manager - Replaces 19 duplicate files
 * Created: August 3, 2025
 */

class ParametricTestManager {
    constructor(managerId = 1) {
        this.managerId = managerId;
        this.items = [];
        this.config = {
            maxItems: 100,
            debug: true,
            name: `TestManager${managerId}`
        };
    }
    
    addItem(item) {
        if (this.items.length < this.config.maxItems) {
            this.items.push({
                id: this.items.length + 1,
                content: item,
                timestamp: new Date().toISOString(),
                source: `TestScript${this.managerId}`
            });
            
            if (this.config.debug) {
                console.log(`Added item to TestManager${this.managerId}: ${item}`);
            }
        } else {
            console.warn(`TestManager${this.managerId} has reached maximum capacity (${this.config.maxItems})`);
        }
    }
    
    processItems() {
        return this.items.map(item => {
            return {
                ...item,
                processed: true,
                processedBy: `TestScript${this.managerId}`,
                processedAt: new Date().toISOString()
            };
        });
    }
    
    getStatistics() {
        return {
            managerId: this.managerId,
            totalItems: this.items.length,
            manager: this.config.name,
            lastUpdate: new Date().toISOString(),
            capacity: this.config.maxItems,
            utilization: Math.round((this.items.length / this.config.maxItems) * 100)
        };
    }
    
    // Additional utility methods
    clearItems() {
        const count = this.items.length;
        this.items = [];
        if (this.config.debug) {
            console.log(`Cleared ${count} items from TestManager${this.managerId}`);
        }
        return count;
    }
    
    getItem(id) {
        return this.items.find(item => item.id === id);
    }
    
    removeItem(id) {
        const index = this.items.findIndex(item => item.id === id);
        if (index !== -1) {
            const removed = this.items.splice(index, 1)[0];
            if (this.config.debug) {
                console.log(`Removed item ${id} from TestManager${this.managerId}`);
            }
            return removed;
        }
        return null;
    }
}

// Factory function to create managers for different test scenarios
function createTestManager(id) {
    return new ParametricTestManager(id);
}

// Batch test runner for multiple managers
class BatchTestRunner {
    constructor() {
        this.managers = new Map();
    }
    
    createManager(id) {
        const manager = new ParametricTestManager(id);
        this.managers.set(id, manager);
        return manager;
    }
    
    getManager(id) {
        return this.managers.get(id);
    }
    
    runBatchTest(managerIds, testData) {
        const results = {};
        
        managerIds.forEach(id => {
            let manager = this.managers.get(id);
            if (!manager) {
                manager = this.createManager(id);
            }
            
            // Add test data
            testData.forEach(item => manager.addItem(item));
            
            // Process and get statistics
            results[id] = {
                processed: manager.processItems(),
                statistics: manager.getStatistics()
            };
        });
        
        return results;
    }
    
    getAllStatistics() {
        const stats = {};
        this.managers.forEach((manager, id) => {
            stats[id] = manager.getStatistics();
        });
        return stats;
    }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ParametricTestManager,
        createTestManager,
        BatchTestRunner
    };
}

// Example usage (replaces individual TestScript functionality)
// const manager1 = createTestManager(1);
// const manager5 = createTestManager(5);
// const batchRunner = new BatchTestRunner();
// const results = batchRunner.runBatchTest([1, 2, 3], ['test1', 'test2']);
