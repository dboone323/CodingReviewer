#!/usr/bin/env python3
"""
Sample Python file for testing
"""

def greet(name):
    """Greet a person by name"""
    return f"Hello, {name}!"

class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"I'm {self.name} and I'm {self.age} years old"

if __name__ == "__main__":
    person = Person("Alice", 30)
    print(person.introduce())
    print(greet("Bob"))