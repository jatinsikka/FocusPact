import SwiftUI
import SwiftData

struct BlocklistView: View {
    @Query(sort: \BlockList.name) var blocklists: [BlockList]
    @StateObject var vm = BlocklistViewModel()
    @EnvironmentObject var blockingService: BlockingService
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fpBackground.ignoresSafeArea()
                Group {
                    if blocklists.isEmpty { emptyStateView } else { blocklistContent }
                }
            }
            .navigationTitle("Blocklists")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showingAddSheet = true } label: {
                        Image(systemName: "plus").foregroundStyle(Color.fpPrimary).fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddSheet) { AddBlocklistSheet(vm: vm) }
            .onAppear { vm.loadPresetsIfNeeded(context: modelContext) }
        }
        .preferredColorScheme(.dark)
    }

    private var blocklistContent: some View {
        List {
            ForEach(blocklists) { blocklist in
                BlocklistRowView(blocklist: blocklist, vm: vm)
                    .listRowBackground(Color.fpSurface)
                    .listRowSeparatorTint(Color.fpBorder)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !blocklist.isPreset {
                            Button(role: .destructive) {
                                vm.deleteBlocklist(blocklist, context: modelContext)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash").font(.system(size: 56)).foregroundStyle(Color.fpTextSecondary)
            Text("No Blocklists Yet").font(.title2).fontWeight(.semibold).foregroundStyle(Color.fpTextPrimary)
            Text("Create a blocklist to start blocking\ndistracting websites during sessions.")
                .font(.subheadline).foregroundStyle(Color.fpTextSecondary).multilineTextAlignment(.center)
            Button { vm.showingAddSheet = true } label: {
                Label("Create Blocklist", systemImage: "plus")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(LinearGradient.fpPrimaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
}

// MARK: - Blocklist Row

private struct BlocklistRowView: View {
    let blocklist: BlockList
    @ObservedObject var vm: BlocklistViewModel
    @EnvironmentObject var blockingService: BlockingService
    @Environment(\.modelContext) var modelContext
    @State private var isExpanded: Bool = false
    @State private var domainInput: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(blocklist.isPreset
                                  ? LinearGradient.fpPrimaryGradient
                                  : LinearGradient(colors: [Color.fpBorder], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 40, height: 40)
                        Image(systemName: blocklist.isPreset ? "shield.fill" : "list.bullet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(blocklist.isPreset ? .white : Color.fpPrimary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(blocklist.name)
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.fpTextPrimary)
                            if blocklist.isPreset {
                                Text("PRESET").font(.caption2).fontWeight(.bold).foregroundStyle(Color.fpPrimary)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.fpPrimary.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        Text("\(blocklist.domains.count) domain\(blocklist.domains.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(Color.fpTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.25), value: isExpanded)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(Color.fpBorder)
                    if blocklist.domains.isEmpty {
                        Text("No domains added yet.")
                            .font(.caption).foregroundStyle(Color.fpTextSecondary)
                            .padding(.vertical, 14).frame(maxWidth: .infinity)
                    } else {
                        ForEach(blocklist.domains, id: \.self) { domain in
                            HStack {
                                Image(systemName: "globe").font(.caption).foregroundStyle(Color.fpTextSecondary)
                                Text(domain).font(.subheadline).foregroundStyle(Color.fpTextPrimary)
                                Spacer()
                                if !blocklist.isPreset {
                                    Button {
                                        withAnimation { vm.removeDomain(domain, from: blocklist, context: modelContext) }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(Color.fpDanger).font(.system(size: 18))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 10)
                            if domain != blocklist.domains.last { Divider().background(Color.fpBorder) }
                        }
                    }
                    if !blocklist.isPreset {
                        Divider().background(Color.fpBorder)
                        HStack(spacing: 10) {
                            TextField("Add domain (e.g. twitter.com)", text: $domainInput)
                                .font(.subheadline).foregroundStyle(Color.fpTextPrimary).tint(Color.fpPrimary)
                                .autocorrectionDisabled().textInputAutocapitalization(.never)
                                .submitLabel(.done).onSubmit { submitDomain() }
                            Button { submitDomain() } label: {
                                Image(systemName: "plus.circle.fill").font(.system(size: 22))
                                    .foregroundStyle(domainInput.trimmingCharacters(in: .whitespaces).isEmpty
                                                     ? Color.fpTextSecondary : Color.fpPrimary)
                            }
                            .buttonStyle(.plain)
                            .disabled(domainInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private func submitDomain() {
        guard !domainInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        vm.addDomain(domainInput, to: blocklist, context: modelContext, service: blockingService)
        domainInput = ""
    }
}

// MARK: - Add Blocklist Sheet

private struct AddBlocklistSheet: View {
    @ObservedObject var vm: BlocklistViewModel
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var domainInput: String = ""
    @State private var domains: [String] = []
    @State private var localError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fpBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Blocklist Name")
                            TextField("e.g. Social Media", text: $name).styledInput()
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Domains to Block")
                            HStack(spacing: 10) {
                                TextField("e.g. twitter.com", text: $domainInput)
                                    .styledInput()
                                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                                    .submitLabel(.done).onSubmit { addDomainToLocal() }
                                Button { addDomainToLocal() } label: {
                                    Text("Add").font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                        .padding(.horizontal, 18).padding(.vertical, 13)
                                        .background(domainInput.trimmingCharacters(in: .whitespaces).isEmpty
                                                    ? LinearGradient(colors: [Color.fpTextSecondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                                    : LinearGradient.fpPrimaryGradient)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(domainInput.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        if !domains.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(domains.count) domain\(domains.count == 1 ? "" : "s") added")
                                    .font(.caption).foregroundStyle(Color.fpTextSecondary)
                                VStack(spacing: 0) {
                                    ForEach(domains, id: \.self) { domain in
                                        HStack {
                                            Image(systemName: "globe").font(.caption).foregroundStyle(Color.fpTextSecondary)
                                            Text(domain).font(.subheadline).foregroundStyle(Color.fpTextPrimary)
                                            Spacer()
                                            Button {
                                                withAnimation { domains.removeAll { $0 == domain } }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(Color.fpDanger).font(.system(size: 18))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 11).background(Color.fpSurface)
                                        if domain != domains.last { Divider().background(Color.fpBorder).padding(.leading, 14) }
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fpBorder, lineWidth: 1))
                            }
                        }
                        if let error = localError ?? vm.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.fpDanger).font(.caption)
                                Text(error).font(.caption).foregroundStyle(Color.fpDanger)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color.fpDanger.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Button {
                            localError = nil; vm.errorMessage = nil
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { localError = "Name cannot be empty."; return }
                            vm.createBlocklist(name: trimmed, domains: domains, context: modelContext)
                        } label: {
                            HStack { Image(systemName: "shield.fill"); Text("Create Blocklist").fontWeight(.semibold) }
                                .font(.body).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                                .background(LinearGradient.fpPrimaryGradient).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Blocklist").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.fpTextSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addDomainToLocal() {
        let cleaned = domainInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        guard !cleaned.isEmpty, !domains.contains(cleaned) else { domainInput = ""; return }
        withAnimation { domains.append(cleaned) }
        domainInput = ""
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
            .textCase(.uppercase).tracking(0.5)
    }
}

private extension View {
    func styledInput() -> some View {
        self.font(.body).foregroundStyle(Color.fpTextPrimary).tint(Color.fpPrimary)
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.fpSurface).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fpBorder, lineWidth: 1))
    }
}
