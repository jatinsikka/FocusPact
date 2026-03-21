import SwiftUI
import SwiftData

struct PactsView: View {
    @Query(sort: \LocalPact.createdAt, order: .reverse) private var pacts: [LocalPact]
    @StateObject private var vm = PactsViewModel()
    @Environment(\.modelContext) private var modelContext

    private var activePacts: [LocalPact] { pacts.filter { $0.isActive } }
    private var completedPacts: [LocalPact] { pacts.filter { $0.isCompleted } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        myCodeCard
                        if activePacts.isEmpty && completedPacts.isEmpty {
                            emptyState
                        } else {
                            if !activePacts.isEmpty {
                                pactSection(title: "Active Pacts", pacts: activePacts)
                            }
                            if !completedPacts.isEmpty {
                                pactSection(title: "Completed", pacts: completedPacts)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .background(Color.fpBackground.ignoresSafeArea())
                .navigationTitle("Friends")
                .toolbarColorScheme(.dark, for: .navigationBar)

                Button { vm.showingAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(LinearGradient.fpPrimaryGradient)
                        .clipShape(Circle())
                        .shadow(color: Color.fpPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $vm.showingAddSheet) {
            AddPactSheet(vm: vm)
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - My Code Card

    private var myCodeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Focus Code")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fpTextSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(vm.myCode)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.fpPrimary)
                        .tracking(6)
                }
                Spacer()
                ShareLink(item: vm.shareText()) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                        Text("Share")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.fpPrimary)
                    .padding(12)
                    .background(Color.fpPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "info.circle").font(.system(size: 12))
                Text("Share your code with friends so they can add you as a pact partner.")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Color.fpTextSecondary)
        }
        .padding(16)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.fpPrimary.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Pact Section

    private func pactSection(title: String, pacts: [LocalPact]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.fpTextPrimary)
            ForEach(pacts) { pact in
                NavigationLink(destination: LocalPactDetailView(pact: pact)) {
                    LocalPactRow(pact: pact)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .leading) {
                    if pact.isActive {
                        Button {
                            vm.completePact(pact, context: modelContext)
                        } label: {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                        }
                        .tint(Color.fpAccent)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        vm.deletePact(pact, context: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.fpTextSecondary)
            Text("No Pacts Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.fpTextPrimary)
            Text("Share your Focus Code with a friend,\nthen tap + to add them as a pact partner.")
                .font(.system(size: 14))
                .foregroundStyle(Color.fpTextSecondary)
                .multilineTextAlignment(.center)
            Button { vm.showingAddSheet = true } label: {
                Label("Add a Friend", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.fpPrimaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - LocalPactRow

struct LocalPactRow: View {
    let pact: LocalPact

    private var statusColor: Color {
        pact.isCompleted ? Color.fpAccent : Color.fpPrimary
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: pact.isCompleted ? "checkmark.circle.fill" : "person.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(pact.partnerName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fpTextPrimary)
                Text("\(pact.durationMinutes) min · Code: \(pact.partnerCode)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fpTextSecondary)
            }
            Spacer()
            Text(pact.isCompleted ? "Done" : "Active")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.fpBorder, lineWidth: 1))
    }
}

// MARK: - AddPactSheet

private struct AddPactSheet: View {
    @ObservedObject var vm: PactsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var partnerCode: String = ""
    @State private var partnerName: String = ""
    @State private var duration: Int = 45
    private let durations = [25, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fpBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Friend's Focus Code")
                            TextField("e.g. AB2C3D", text: $partnerCode)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.fpPrimary)
                                .tracking(6)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .background(Color.fpSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                                    partnerCode.isEmpty ? Color.fpBorder : Color.fpPrimary, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Friend's Name (optional)")
                            TextField("e.g. Alex", text: $partnerName)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.fpTextPrimary)
                                .tint(Color.fpPrimary)
                                .padding(14)
                                .background(Color.fpSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fpBorder, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Pact Duration")
                            HStack(spacing: 8) {
                                ForEach(durations, id: \.self) { opt in
                                    Button { duration = opt } label: {
                                        Text("\(opt)m")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(duration == opt ? .white : Color.fpTextSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(duration == opt
                                                ? LinearGradient.fpPrimaryGradient
                                                : LinearGradient(colors: [Color.fpSurface], startPoint: .leading, endPoint: .trailing))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }

                        Button {
                            vm.createPact(
                                partnerCode: partnerCode,
                                partnerName: partnerName,
                                durationMinutes: duration,
                                context: modelContext
                            )
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Create Pact").fontWeight(.semibold)
                            }
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(partnerCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LinearGradient(colors: [Color.fpTextSecondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient.fpPrimaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(partnerCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Pact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.fpTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
            .textCase(.uppercase).tracking(0.5)
    }
}
