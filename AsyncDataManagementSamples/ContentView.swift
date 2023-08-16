import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("Case 0 Before", destination: Case0_Before())

                    NavigationLink("Case 0 After", destination: Case0_After())
                } header: {
                    Text("Inroduction")
                }

                Section {
                    NavigationLink("Case 1 Before", destination: Case1_Before())

                    NavigationLink("Case 1 After", destination: Case1_After())

                    NavigationLink("Case 1 Alt", destination: Case1_Alt())
                } header: {
                    Text("reLoading")
                }

                Section {
                    NavigationLink("Case 2 Before", destination: Case2_Before())

                    NavigationLink("Case 2 After", destination: Case2_After())

                    NavigationLink("Case 2 Alt", destination: Case2_Alt())
                } header: {
                    Text("retryLoading")
                }

                Section {
                    NavigationLink("Case 3", destination: Case3())
                } header: {
                    Text("paging")
                }

                Section {
                    NavigationLink("Case EX", destination: CaseEX())

                    NavigationLink("Case EX NG", destination: CaseEX_NG())

                    NavigationLink("Case EX Paging", destination: CaseEX_Paging())
                } header: {
                    Text("placeholder")
                }

                Section {
                    NavigationLink("Case 4", destination: Case4())

                    NavigationLink("Case 4 Paging", destination: Case4_Paging())
                } header: {
                    Text("reLoadingFailure")
                }

                templateViews
            }
        }
    }

    @ViewBuilder
    var templateViews: some View {
        Section {
            NavigationLink("SwitchViewStyle", destination: SwitchViewStyleSample())

            NavigationLink("SwitchViewStyle Paging", destination: SwitchViewStylePagingSample())
        } header: {
            Text("switch view style")
        }

        Section {
            NavigationLink("FetchViewStyle", destination: FetchViewStyleSample())

            NavigationLink("FetchViewStyle Paging", destination: FetchViewStylePagingSample())
        } header: {
            Text("fetch view style")
        }

        Section {
            NavigationLink("BindableFetchViewStyle", destination: BindableFetchViewStyleSample())

            NavigationLink("BindableFetchViewStyle Paging", destination: BindableFetchViewStylePagingSample())
        } header: {
            Text("bindable fetch view style")
        }

        Section {
            NavigationLink("SimpleFetchViewStyle", destination: SimpleFetchViewStyleSample())

            NavigationLink("SimpleFetchViewStyle Paging", destination: SimpleFetchViewStylePagingSample())
        } header: {
            Text("simple fetch view style")
        }
    }
}
