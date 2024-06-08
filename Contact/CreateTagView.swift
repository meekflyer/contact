//
//  CreateTagView.swift
//  Contact
//
//  Created by Thomas Patrick on 6/5/24.
//

import SwiftUI
import SwiftData

struct CreateTagView: View {
    @Environment(\.self) var environment
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @State private var name: String = ""
    @State private var parentID: String = "-1"

    let closeView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("New Tag")
                .font(.title2)
                .bold()

            Picker("Subtag of", selection: $parentID) {
                Text("Nothing").tag("-1")
                ForEach(tags) { tag in
                    Text(tag.name).tag(tag.id)
                }
            }
            .pickerStyle(.menu)

            TextField("name", text: $name, prompt: Text("Name"))
                .frame(width: 150)
                .onSubmit {
                    addItem(name: name, color: .gray, parentID: parentID == "-1" ? nil : parentID)
                }
            Button("Save") {
                addItem(name: name, color: .gray, parentID: parentID == "-1" ? nil : parentID)
            }
        }
        .padding()
    }

    private func addItem(name: String, color: Color, parentID: String? = nil) {
        if !name.isEmpty {
            withAnimation {
                let newItem = Tag(name: name, color: color.resolve(in: environment), parentID: parentID)
                modelContext.insert(newItem)
                closeView()
            }
        }
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 25.0)
        .popover(isPresented: .constant(true)) {
            CreateTagView(closeView: {})
        }
}
