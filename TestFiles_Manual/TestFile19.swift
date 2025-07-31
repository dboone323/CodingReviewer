//
//  TestFile19.swift
//  Manual Test File 19
//

import Foundation
import SwiftUI

class TestClass19: ObservableObject {
    @Published var data: [String] = [];
    
    func loadData() {
        data = Array(1...10).map { "Item $0 from TestFile19" }
    }
    
    func processData() {
        print("Processing data in TestFile19")
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

struct TestView19: View {
    @StateObject private var testClass = TestClass19();
    
    var body: some View {
        VStack {
            Text("Test View 19")
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
