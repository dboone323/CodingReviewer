//
//  TestFile15.swift
//  Manual Test File 15
//

import Foundation
import SwiftUI

class TestClass15: ObservableObject {
    @Published var data: [String] = []
    
    func loadData() {
        data = Array(1...10).map { "Item $0 from TestFile15" }
    }
    
    func processData() {
        print("Processing data in TestFile15")
        for item in data {
            print("  - \(item)")
        }
    }
    
    func complexMethod(param1: String, param2: Int) -> String {
        if param2 > 5 {
            return "Complex result from \(param1) with value \(param2)"
        } else {
            return "Simple result from \(param1)"
        }
    }
}

struct TestView15: View {
    @StateObject private var testClass = TestClass15()
    
    var body: some View {
        VStack {
            Text("Test View 15")
                .font(.title)
            
            Button("Load Data") {
                testClass.loadData()
            }
            
            List(testClass.data, id: \.self) { item in
                Text(item)
            }
        }
        .onAppear {
            testClass.loadData()
        }
    }
}
