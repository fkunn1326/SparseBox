import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
            MainView()
				.tabItem {
					Image(systemName: "square.stack.3d.up.fill")
					Text("main")
				}
            SubView()
				.tabItem {
					Image(systemName: "wrench")
					Text("sub")
				}
        }
    }
}
