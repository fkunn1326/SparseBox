import SwiftUI

// show text hello world

struct SubView: View {
    @State private var filepath = ""
    @State private var fileres = ""

    var body: some View {
        NavigationView {
            Form {
                // input field
                Section {
                    HStack {
                        Text("File Path")
                        Spacer()
                        TextField("File Path", text: $filepath)
                            .multilineTextAlignment(.trailing)
                        Button("Check") {
                            Task {
                                let f_ok = access(filepath, F_OK) == 0
                                let r_ok = access(filepath, R_OK) == 0
                                let w_ok = access(filepath, W_OK) == 0

                                fileres = "F: \(f_ok), R: \(r_ok), W: \(w_ok),"
                            }
                        }
                    }
                } header: {
                    Text("File existence checker")
                } footer: {
                    Text(fileres)
                }
            }
        }
    }
}