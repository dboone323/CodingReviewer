// Sample JavaScript file for testing

class User {
    constructor(name, email) {
        this.name = name;
        this.email = email;
    }
    
    greet() {
        return `Hello, I'm ${this.name} (${this.email})`;
    }
    
    validateEmail() {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(this.email);
    }
}

function createUser(name, email) {
    const user = new User(name, email);
    if (user.validateEmail()) {
        console.log(user.greet());
        return user;
    } else {
        console.error("Invalid email address");
        return null;
    }
}

// Test the functionality
const testUser = createUser("John Doe", "john@example.com");
console.log("User created:", testUser !== null);