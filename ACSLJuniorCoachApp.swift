import AppKit
import SwiftUI

// MARK: - App

@main
struct ACSLJuniorCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ACSLJuniorCoachRootView()
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// MARK: - Teaching environment

private struct PresentationModeKey: EnvironmentKey {
    static let defaultValue = false
}

private struct FontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var presentationModeEnabled: Bool {
        get { self[PresentationModeKey.self] }
        set { self[PresentationModeKey.self] = newValue }
    }

    var teachingScale: CGFloat {
        get { self[FontScaleKey.self] }
        set { self[FontScaleKey.self] = newValue }
    }
}

// MARK: - Models

private enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Coach Dashboard"
    case contest1 = "Contest 1 Training"
    case contest2 = "Contest 2 Training"
    case contest3 = "Contest 3 Training"
    case contest4 = "Contest 4 Training"
    case mockExams = "Team Mock Exams"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: return "person.3.sequence.fill"
        case .contest1: return "1.square.fill"
        case .contest2: return "2.square.fill"
        case .contest3: return "3.square.fill"
        case .contest4: return "4.square.fill"
        case .mockExams: return "checkmark.seal.fill"
        }
    }

    var contestNumber: Int? {
        switch self {
        case .contest1: return 1
        case .contest2: return 2
        case .contest3: return 3
        case .contest4: return 4
        default: return nil
        }
    }
}

private struct RoundScore: Equatable {
    var shortAnswer: Int
    var programming: Int

    var total: Int { min(5, max(0, shortAnswer)) + min(5, max(0, programming)) }
}

private struct TeamStudent: Identifiable, Equatable {
    let id: UUID
    var name: String
    var roleNote: String
    var scores: [RoundScore]

    var seasonTotal: Int { scores.reduce(0) { $0 + $1.total } }
    var qualifiesForFinals: Bool { seasonTotal >= 24 }

    static let finalsThreshold = 24
    static let seasonMax = 40
}

private enum ContestTab: String, CaseIterable, Identifiable {
    case slides = "Presentation Slides"
    case sandbox = "Interactive Sandbox"
    case python = "Python HackerRank Simulator"

    var id: String { rawValue }
}

private struct SlideCard {
    let title: String
    let bullets: [String]
    let diagram: String
    var coachNote: String = ""
}

private struct ContestSyllabus {
    let contest: Int
    let title: String
    let topics: [String]
    let slides: [SlideCard]
    let pythonPrompt: String
    let pythonTemplate: String
    let pythonNotes: [String]
    let homework: String
}

private struct MockQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let answer: String
    let derivation: String
}

private struct MockExam {
    let contest: Int
    let title: String
    let questions: [MockQuestion]
}

// MARK: - Root

private struct ACSLJuniorCoachRootView: View {
    @State private var selection: SidebarSection = .dashboard
    @State private var presentationMode = false
    @State private var selectedStudentID: UUID
    @State private var roster: [TeamStudent]
    @State private var revealMockKeys = false

    init() {
        let seed = Self.seedRoster()
        _roster = State(initialValue: seed)
        _selectedStudentID = State(initialValue: seed.first?.id ?? UUID())
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    Section("Classroom") {
                        ForEach(SidebarSection.allCases) { item in
                            Label(item.rawValue, systemImage: item.systemImage)
                                .tag(item)
                        }
                    }
                }
                .listStyle(.sidebar)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Role: ACSL Team Instructor / Coach")
                        .font(.caption.weight(.semibold))
                    Text("Junior Division · Theory + Python")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(presentationMode ? "Presentation Mode" : "Self-Study Mode")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(presentationMode ? Color.orange : Color.accentColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.ultraThinMaterial)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    CoachDashboardView(
                        roster: $roster,
                        selectedStudentID: $selectedStudentID,
                        presentationMode: $presentationMode
                    )
                case .contest1, .contest2, .contest3, .contest4:
                    ContestTrainingView(
                        contest: selection.contestNumber ?? 1,
                        selectedStudentName: selectedName
                    )
                case .mockExams:
                    TeamMockExamsView(
                        selectedStudentName: selectedName,
                        revealKeys: $revealMockKeys
                    )
                }
            }
            .environment(\.presentationModeEnabled, presentationMode)
            .environment(\.teachingScale, presentationMode ? 1.42 : 1.0)
        }
        .navigationTitle(selection.rawValue)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("Focus student", selection: $selectedStudentID) {
                    ForEach(roster) { student in
                        Text(student.name).tag(student.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 120)
            }
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $presentationMode) {
                    Text(presentationMode ? "Presentation" : "Self-Study")
                }
                .toggleStyle(.switch)
                .help("Enlarge type and code blocks for projector teaching")
            }
        }
    }

    private var selectedName: String {
        roster.first(where: { $0.id == selectedStudentID })?.name ?? "Soha"
    }

    private static func seedRoster() -> [TeamStudent] {
        [
            TeamStudent(
                id: UUID(),
                name: "Soha",
                roleNote: "Junior Division · theory and Python HackerRank I/O",
                scores: [
                    RoundScore(shortAnswer: 4, programming: 4),
                    RoundScore(shortAnswer: 5, programming: 3),
                    RoundScore(shortAnswer: 3, programming: 4),
                    RoundScore(shortAnswer: 0, programming: 0)
                ]
            )
        ]
    }
}

// MARK: - Dashboard

private struct CoachDashboardView: View {
    @Binding var roster: [TeamStudent]
    @Binding var selectedStudentID: UUID
    @Binding var presentationMode: Bool
    @Environment(\.teachingScale) private var scale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                officialMatrix
                teamTable
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACSL Junior Division · Season Tracker")
                .font(.system(size: 28 * scale, weight: .bold, design: .rounded))
            Text("Each round is 10 points: 5 Short-Answer + 5 Programming (hidden HackerRank cases). Season max 40. Finals qualification threshold is 24.")
                .font(.system(size: 14 * scale))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $presentationMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Presentation Mode")
                        .font(.headline)
                    Text("Larger type, maximized code blocks for projector teaching")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(.top, 4)
        }
    }

    private var officialMatrix: some View {
        HStack(spacing: 12) {
            MetricTile(title: "Short-Answer", value: "5 pts", detail: "per contest")
            MetricTile(title: "Programming", value: "5 pts", detail: "hidden tests")
            MetricTile(title: "Round max", value: "10", detail: "theory + code")
            MetricTile(title: "Season max", value: "40", detail: "4 contests")
            MetricTile(title: "Finals bar", value: "24", detail: "qualification")
        }
    }

    private var teamTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team tracker")
                .font(.system(size: 18 * scale, weight: .semibold))

            ForEach($roster) { $student in
                StudentProgressCard(
                    student: $student,
                    isSelected: student.id == selectedStudentID
                )
                .onTapGesture { selectedStudentID = student.id }
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10 * scale, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
            Text(detail)
                .font(.system(size: 11 * scale))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StudentProgressCard: View {
    @Binding var student: TeamStudent
    var isSelected: Bool
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(student.name)
                            .font(.system(size: 18 * scale, weight: .semibold))
                        if student.qualifiesForFinals {
                            Text("FINALS")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.2), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                    Text(student.roleNote)
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(student.seasonTotal) / \(TeamStudent.seasonMax)")
                    .font(.system(size: 20 * scale, weight: .bold, design: .monospaced))
            }

            ProgressView(value: Double(min(student.seasonTotal, TeamStudent.finalsThreshold)), total: Double(TeamStudent.finalsThreshold)) {
                Text("Progress to 24-point Finals threshold")
                    .font(.system(size: 11 * scale))
            }
            .tint(student.qualifiesForFinals ? .green : .accentColor)

            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("C\(idx + 1)")
                            .font(.caption.weight(.semibold))
                        Stepper("SA \(student.scores[idx].shortAnswer)/5", value: $student.scores[idx].shortAnswer, in: 0...5)
                        Stepper("PR \(student.scores[idx].programming)/5", value: $student.scores[idx].programming, in: 0...5)
                        Text("= \(student.scores[idx].total)")
                            .font(.caption.monospaced())
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Contest training

private struct ContestTrainingView: View {
    let contest: Int
    let selectedStudentName: String
    @State private var tab: ContestTab = .slides
    @Environment(\.teachingScale) private var scale

    var body: some View {
        let syllabus = ContestCurriculum.syllabus(for: contest)
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(syllabus.title)
                        .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                    Text("Teaching \(selectedStudentName) · \(syllabus.topics.joined(separator: " · "))")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Tab", selection: $tab) {
                    ForEach(ContestTab.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 640)
            }
            .padding(16)

            Divider()

            Group {
                switch tab {
                case .slides:
                    PresentationSlidesView(syllabus: syllabus)
                case .sandbox:
                    InteractiveSandboxView(contest: contest)
                case .python:
                    PythonHackerRankSimulatorView(contest: contest, studentName: selectedStudentName)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private enum ContestCurriculum {
    static func syllabus(for n: Int) -> ContestSyllabus {
        switch n {
        case 1:
            return ContestSyllabus(
                contest: 1,
                title: "Contest 1 — Number Systems, Recursion, Branch Tracing",
                topics: ["Number Systems", "Recursion", "Branch Tracing"],
                slides: [
                    SlideCard(
                        title: "Lesson map (60–75 min)",
                        bullets: [
                            "Part A (25 min): Computer Number Systems — place value, 2/8/10/16, grouping shortcuts, add in another base.",
                            "Part B (20 min): Recursive functions — find the base case, build a table, unwind the tree.",
                            "Part C (15 min): Branch tracing (What Does This Program Do?) — if/elif/else, and/or, print vs return.",
                            "Part D (10 min): Python HackerRank I/O — input().strip().split() and int(s, base).",
                            "Soha should leave able to convert any ACSL numeral on paper in under a minute, and trace a 6-line if-program without guessing."
                        ],
                        diagram: "Contest 1 short-answer = 5 questions mixed from A+B+C\nProgramming = 5 hidden tests on parsing + conversion/recursion",
                        coachNote: "Write the three topic names on the board first. Tell Soha every Contest 1 paper is those three skills only — nothing else."
                    ),
                    SlideCard(
                        title: "Number systems — what ACSL actually asks",
                        bullets: [
                            "Four bases only: binary 2, octal 8, decimal 10, hexadecimal 16.",
                            "A trailing subscript names the base: 1011₂ , 17₈ , 2F₁₆ , 47₁₀. If there is no subscript, assume decimal.",
                            "Hex digits: 0–9 then A=10, B=11, C=12, D=13, E=14, F=15. Case does not matter (a = A).",
                            "Typical stems: convert X from base A to base B; add two numbers in the same base; ‘how many bits?’ via grouping."
                        ],
                        diagram: "Legal hex: 0 1 2 3 4 5 6 7 8 9 A B C D E F\nIllegal in octal: 8 and 9   Illegal in binary: any digit except 0,1",
                        coachNote: "Quiz out loud: ‘Is 18₈ legal?’ No — 8 is not an octal digit. Catch this before converting."
                    ),
                    SlideCard(
                        title: "Place value — the only formula you need",
                        bullets: [
                            "Value = dₙ·bⁿ + dₙ₋₁·bⁿ⁻¹ + … + d₁·b¹ + d₀·b⁰.",
                            "Positions count from the right, starting at exponent 0.",
                            "Worked: 1A₁₆ = 1·16¹ + 10·16⁰ = 16 + 10 = 26₁₀.",
                            "Worked: 2F₁₆ = 2·16 + 15 = 47₁₀.",
                            "Worked: 77₈ = 7·8 + 7 = 63₁₀.",
                            "Worked: 101101₂ = 32+8+4+1 = 45₁₀."
                        ],
                        diagram: "  1 A   hex\n 16¹ 16⁰\n  1×16 + 10×1 = 26\n\n  1 0 1 1 0 1   binary\n 32 16  8  4  2  1\n 32 + 0 + 8 + 4 + 0 + 1 = 45",
                        coachNote: "Always draw the power row under the digits. Do not skip this on paper even when it feels slow — this is how Soha avoids off-by-one exponents."
                    ),
                    SlideCard(
                        title: "Decimal → other bases (repeated divide)",
                        bullets: [
                            "To convert N₁₀ to base b: divide by b, record remainders, read remainders from last to first.",
                            "Example 26₁₀ → hex: 26÷16 = 1 remainder 10 (A). Stop. Answer 1A₁₆.",
                            "Example 45₁₀ → binary: 45÷2 remainders 1,0,1,1,0,1 then reverse → 101101₂.",
                            "Example 63₁₀ → octal: 63÷8 = 7 r 7 → 77₈.",
                            "Check by converting back with place value. If it does not match, a remainder was written in the wrong order."
                        ],
                        diagram: "45 ÷ 2 = 22 r 1\n22 ÷ 2 = 11 r 0\n11 ÷ 2 =  5 r 1\n 5 ÷ 2 =  2 r 1\n 2 ÷ 2 =  1 r 0\n 1 ÷ 2 =  0 r 1   ← last remainder is the leftmost bit\nRead up: 101101₂",
                        coachNote: "Remainders are written top-to-bottom as you compute, then you read bottom-to-top for the answer. Circle the last remainder."
                    ),
                    SlideCard(
                        title: "Speed trick — grouping bits",
                        bullets: [
                            "Binary ↔ octal: groups of 3 bits (because 2³ = 8). Pad with 0s on the LEFT, never the right.",
                            "Binary ↔ hex: groups of 4 bits (because 2⁴ = 16). Pad left with 0s.",
                            "101101₂ → octal: 101 101 → 5 5 → 55₈.",
                            "101101₂ → hex: 0010 1101 → 2 D → 2D₁₆.",
                            "Check: 2D₁₆ = 2·16+13 = 45, and 101101₂ was 45. Same number."
                        ],
                        diagram: "to octal   …  101 | 101\n                 5  |  5     → 55₈\n\nto hex     00 10 | 1101\n               2  |    D     → 2D₁₆",
                        coachNote: "This is the #1 ACSL time-saver. Practice three conversions using ONLY grouping, no place-value expansion."
                    ),
                    SlideCard(
                        title: "Adding in another base",
                        bullets: [
                            "Add column by column from the right. If the column sum ≥ the base, write (sum mod base) and carry (sum ÷ base).",
                            "Binary: 1+1 = 10₂ → write 0, carry 1.  1+1+1 = 11₂ → write 1, carry 1.",
                            "Hex: A+7 = 10+7 = 17₁₀ = 11₁₆ → write 1, carry 1.",
                            "Worked: 1011₂ + 0110₂ = 10001₂.",
                            "Worked: 2F₁₆ + 13₁₆ = 42₁₆  (15+3=18=12₁₆ write 2 carry 1; 2+1+1=4)."
                        ],
                        diagram: "   1 0 1 1\n+  0 1 1 0\n  --------\n 1 0 0 0 1     (carry 1 from the two 1s in the 2s place)\n\n   2 F\n+  1 3\n  ----\n   4 2₁₆",
                        coachNote: "Have Soha say the column in decimal first (‘F is 15, plus 3 is 18’), then convert 18 back into hex."
                    ),
                    SlideCard(
                        title: "Board drill — number systems (do now)",
                        bullets: [
                            "1) 1C₁₆ → decimal.  2) 110111₂ → octal.  3) 50₁₀ → hex.",
                            "4) 67₈ → binary (via grouping).  5) 1010₂ + 1111₂.",
                            "Answers: 28 ; 67₈ ; 32₁₆ ; 110111₂ ; 11001₂.",
                            "If any miss: redo with the power row drawn. No calculator except the sandbox tab to check."
                        ],
                        diagram: "1) 1×16+12=28\n2) 110 111 → 6 7 → 67₈\n3) 50÷16=3 r 2 → 32₁₆\n4) 67₈ = 110 111₂\n5) 1010+1111=11001₂ (10+15=25=11001₂)",
                        coachNote: "Pause here. Do not start recursion until these five are correct. Use Interactive Sandbox to verify live."
                    ),
                    SlideCard(
                        title: "Recursion — three questions every time",
                        bullets: [
                            "1) What is the base case? (the line that does not call f again)",
                            "2) What is the recursive case? (how f(n) uses a smaller argument)",
                            "3) What exactly is returned? (an expression, not ‘it calls itself’)",
                            "ACSL writes piecewise math: f(0)=1,  f(n)=n+f(n−1) for n>0.",
                            "Python equivalent: if n==0: return 1 else: return n + f(n-1)."
                        ],
                        diagram: "f(n) = n + f(n-1),  f(0)=1\n\nf(4) = 4 + f(3)\n     = 4 + 3 + f(2)\n     = 4 + 3 + 2 + f(1)\n     = 4 + 3 + 2 + 1 + f(0)\n     = 4+3+2+1+1 = 11",
                        coachNote: "Ban the word ‘factorial’ until the table is filled. f(n)=n+f(n-1), f(0)=1 is NOT n! — it is triangular numbers plus 1."
                    ),
                    SlideCard(
                        title: "Recursion method — build a table, not a story",
                        bullets: [
                            "Start at the base case and compute upward. This is faster and fewer mistakes than drawing a huge tree.",
                            "f(0)=1",
                            "f(1)=1+f(0)=2",
                            "f(2)=2+f(1)=4",
                            "f(3)=3+f(2)=7",
                            "f(4)=4+f(3)=11",
                            "If ACSL asks f(4), the answer is 11. Box it."
                        ],
                        diagram: " n | f(n)\n 0 |  1     ← given\n 1 |  2\n 2 |  4\n 3 |  7\n 4 | 11     ← asked",
                        coachNote: "Soha writes the table on every recursion question. Trees are for showing the class; tables are for scoring points."
                    ),
                    SlideCard(
                        title: "Harder recursion ACSL uses",
                        bullets: [
                            "Two arguments: f(x,y)=f(x−1,y)+f(x,y−1), with f(0,*)=1 and f(*,0)=1. Fill a grid.",
                            "Conditional: f(n)=f(n−1)+n if n even, else f(n−1)−1. Trace parity each row.",
                            "Nested: f(n)=f(f(n−1)). Compute inner first, then outer.",
                            "Example: f(0)=2, f(n)=n·f(n−1)+1.  f(1)=1·2+1=3, f(2)=2·3+1=7, f(3)=3·7+1=22.",
                            "Example two-arg: f(1,1)=f(0,1)+f(1,0)=1+1=2."
                        ],
                        diagram: "Grid for f(x,y), base 1 on axes:\n      y=0  y=1  y=2\nx=0    1    1    1\nx=1    1    2    3\nx=2    1    3    6\n(binomial-looking — that is OK to notice after the grid is filled)",
                        coachNote: "For two-argument recursion, draw the grid on the projector. Never try to recurse in your head past f(2,2)."
                    ),
                    SlideCard(
                        title: "Board drill — recursion (do now)",
                        bullets: [
                            "A) f(0)=3, f(n)=2·f(n−1)−1. Find f(4).",
                            "B) g(0)=0, g(1)=1, g(n)=g(n−1)+g(n−2)+1. Find g(5).",
                            "C) h(n)=n−h(n−1), h(0)=0. Find h(6).",
                            "Answers: A) 33   B) 12   C) 3. Watch the off-by-one: f(0) counts as a row."
                        ],
                        diagram: "A: 3, 5, 9, 17, 33…  f(4)=17?  f(1)=5, f(2)=9, f(3)=17, f(4)=33.\n   CORRECT A = 33. (Coach: trap — off-by-one on which n)\nB: 0,1,2,4,7,12  g(5)=12\nC: 0,1,1,2,2,3,3  h(6)=3",
                        coachNote: "Point out the off-by-one trap in A. Count rows: f(0),f(1),f(2),f(3),f(4). Answer is 33, not 17. This is a real ACSL miss."
                    ),
                    SlideCard(
                        title: "Branch tracing — rules of the road",
                        bullets: [
                            "This is ACSL ‘What Does This Program Do?’ for Junior: short Python (or ACSL pseudocode) with if/else.",
                            "Make a two-column table: Line | a, b, c, printed.",
                            "Python: indentation IS the block. The else pairs with the nearest unmatched if at the same indent.",
                            "== tests equality. = assigns. Mixing them is a contest killer.",
                            "and / or short-circuit: False and X never evaluates X; True or X never evaluates X.",
                            "print outputs. return leaves the function. ACSL may ask the printed line or the final variables."
                        ],
                        diagram: "a, b = 7, 3\nif a > b:\n    a = a - b\nelse:\n    b = b - a\nprint(a, b)\n\nTrace: 7>3 True → a=4. else skipped. print 4 3",
                        coachNote: "Act it out: cover the else with your hand when the if is true. Students still peek at the else — that is the bug."
                    ),
                    SlideCard(
                        title: "Worked traces (project these)",
                        bullets: [
                            "Nested if: if a>5: if a>10: a=0 else: a=a-1. For a=8 → inner else → a=7. For a=12 → a=0. For a=3 → no change.",
                            "elif chain: only ONE arm runs. After a hit, skip the rest.",
                            "range is Contest 2, but if it appears: range(1,4) is 1,2,3 — stop before 4.",
                            "Worked: a=5; if a%2==0: a=a//2 else: a=3*a+1 → odd → 16."
                        ],
                        diagram: "a = 8\nif a > 5:\n    if a > 10:\n        a = 0\n    else:\n        a = a - 1\nprint(a)          # 7\n\na = 5\nif a % 2 == 0:\n    a = a // 2\nelse:\n    a = 3 * a + 1\nprint(a)          # 16",
                        coachNote: "Have Soha fill the variable table before looking at the answer. Then reveal."
                    ),
                    SlideCard(
                        title: "Board drill — branch tracing (do now)",
                        bullets: [
                            "P1: a,b=4,9; if a>b: a=a+1 elif a==b: a=0 else: b=b-a; print(a,b)",
                            "P2: n=7; if n>10: n=n-10; if n>5: n=n-5; print(n)   (two separate ifs, not else)",
                            "P3: x=2; y=5; if x<y and y<10: x=x*y; print(x)",
                            "Answers: P1 → 4 5    P2 → 2    P3 → 10"
                        ],
                        diagram: "P1: 4>9 False, 4==9 False, else b=9-4=5 → 4 5\nP2: 7>10 False (skip). 7>5 True → n=2. print 2\nP3: True and True → x=10",
                        coachNote: "P2 is the classic trap: two ifs, not if/else. Both can run. Circle that on the board."
                    ),
                    SlideCard(
                        title: "How this shows up in the programming problem",
                        bullets: [
                            "Hidden tests send raw stdin: often ‘1A 16’ or two integers on one line.",
                            "Parse with parts = input().strip().split()  then int(parts[0], int(parts[1])) if converting.",
                            "Or: tokens = sys.stdin.read().strip().split()  when there may be extra whitespace or multiple lines.",
                            "Print only the number. No ‘The answer is’. Return type int unless the spec says a string.",
                            "Switch to the Python tab next and copy homework for Soha."
                        ],
                        diagram: "stdin:  1A 16\\n\nparts = ['1A', '16']\nprint(int(parts[0], int(parts[1])))   # 26\n\n# never:\n# x = input('enter number:')",
                        coachNote: "End class by watching Soha convert 2F 16 in the sandbox, then paste the homework into a .py file."
                    )
                ],
                pythonPrompt: "Contest 1 programming almost always starts with parsing tokens, then either converting a numeral or evaluating a small recursive rule. Teach both.",
                pythonTemplate: """
                import sys

                def to_decimal(value: str, base: int) -> int:
                    return int(value.strip(), base)

                def f(n: int) -> int:
                    # f(0)=1, f(n)=n+f(n-1)  — same as the board table
                    if n == 0:
                        return 1
                    return n + f(n - 1)

                def solve() -> int:
                    data = sys.stdin.read().strip().split()
                    # Hidden test shapes you must handle:
                    #   "1A 16"           → convert
                    #   "4"               → just n for f(n)
                    #   "convert 2F 16"   → skip a word, then numeral + base
                    if data[0].lower() == "convert":
                        return to_decimal(data[1], int(data[2]))
                    if len(data) >= 2:
                        return to_decimal(data[0], int(data[1]))
                    return f(int(data[0]))

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "input().strip() removes the newline. .split() with no args splits on any whitespace.",
                    "int('1A', 16) is 26. int('77', 8) is 63. Never write your own hex map unless the problem forbids int().",
                    "If the spec returns int, print(solve()) is enough. Do not print a list or a tuple.",
                    "Recursion in Python needs a base case or you get RecursionError on hidden tests.",
                    "Sample you should run locally: echo '2F 16' | python3 contest1.py   → 47",
                    "Second sample: echo '4' | python3 contest1.py   → 11"
                ],
                homework: """
                # Contest 1 homework for Soha
                # PAPER (do first, then check in the app sandbox)
                # N1. 1C16 → decimal
                # N2. 1101112 → octal (grouping)
                # N3. 5010 → hex (repeated divide)
                # N4. 678 → binary
                # N5. 10102 + 11112
                # R1. f(0)=3, f(n)=2*f(n-1)-1. Find f(4).  (answer 33)
                # R2. g(0)=0, g(1)=1, g(n)=g(n-1)+g(n-2)+1. Find g(5).  (12)
                # B1. a,b=4,9; if a>b: a=a+1 elif a==b: a=0 else: b=b-a; print a,b
                # B2. n=7; if n>10: n=n-10; if n>5: n=n-5; print n
                #
                # CODE — save as contest1.py and pipe stdin
                import sys

                def homework_convert() -> int:
                    tokens = sys.stdin.read().strip().split()
                    numeral, base = tokens[0], int(tokens[1])
                    return int(numeral, base)

                if __name__ == "__main__":
                    print(homework_convert())
                """
            )
        case 2:
            return ContestSyllabus(
                contest: 2,
                title: "Contest 2 — Prefix/Postfix, Bit Flicking, Loop Tracing",
                topics: ["Prefix / Postfix", "Bit Flicking", "Loop Tracing"],
                slides: [
                    SlideCard(title: "Prefix & Postfix", bullets: [
                        "Infix: operator between operands (A + B). Prefix: + A B. Postfix: A B +.",
                        "Postfix evaluation uses a stack: push numbers; on operator, pop two, push result.",
                        "Prefix is evaluated right-to-left with the same stack idea.",
                        "ACSL uses single-letter operands or integers; operators + − * / ^."
                    ], diagram: "Infix: (3+4)*5\nPostfix: 3 4 + 5 *\nPrefix: * + 3 4 5"),
                    SlideCard(title: "Bit-String Flicking", bullets: [
                        "Treat strings of 0/1 as bits. Operators: NOT, AND, OR, XOR, LSHIFT, RSHIFT, LCIRC, RCIRC.",
                        "NOT flips bits. AND/OR/XOR are bitwise on equal-length strings.",
                        "LSHIFT / RSHIFT drop bits and fill 0. LCIRC / RCIRC rotate.",
                        "Apply inner operators first; ACSL defines precedence in the topic description."
                    ], diagram: "1011 AND 1101 = 1001\nNOT 1010 = 0101\nLSHIFT 1011 = 0110"),
                    SlideCard(title: "Loop Tracing", bullets: [
                        "for and while: write a table of i, accumulators, and printed values.",
                        "Python range(a,b) is [a, a+1, …, b-1] — exclusive end.",
                        "Nested loops: inner loop completes fully for each outer iteration.",
                        "Watch off-by-one and whether the update happens before or after the print."
                    ], diagram: "s = 0\nfor i in range(1,4):\n    s += i\n# s = 6")
                ],
                pythonPrompt: "Read a postfix expression of integers and + - * operators. Evaluate and print the integer result.",
                pythonTemplate: """
                import sys

                def eval_postfix(tokens):
                    stack = []
                    for tok in tokens:
                        if tok in "+-*":
                            b, a = stack.pop(), stack.pop()
                            if tok == "+":
                                stack.append(a + b)
                            elif tok == "-":
                                stack.append(a - b)
                            else:
                                stack.append(a * b)
                        else:
                            stack.append(int(tok))
                    return stack[-1]

                def solve() -> int:
                    tokens = sys.stdin.read().strip().split()
                    return eval_postfix(tokens)

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "split() already tokenizes '3 4 + 5 *' into a list — do not parse character by character.",
                    "Pop order: second operand is popped first (b), then first operand (a).",
                    "Hidden tests send one line of tokens. Your function should return int.",
                    "If the spec says print only the number, do not print debug traces."
                ],
                homework: """
                # Contest 2 homework
                # Evaluate postfix 5 1 2 + 4 * + 3 - on paper (should be 14), then code it.

                import sys

                def eval_postfix(expr: str) -> int:
                    stack = []
                    for tok in expr.strip().split():
                        if tok in "+-*":
                            b, a = stack.pop(), stack.pop()
                            stack.append({"+" : a+b, "-" : a-b, "*" : a*b}[tok])
                        else:
                            stack.append(int(tok))
                    return stack[-1]

                if __name__ == "__main__":
                    print(eval_postfix(sys.stdin.read()))
                """
            )
        case 3:
            return ContestSyllabus(
                contest: 3,
                title: "Contest 3 — Boolean Algebra, Stacks/Queues, Array Tracing",
                topics: ["Boolean Algebra", "Stacks / Queues", "Array Tracing"],
                slides: [
                    SlideCard(title: "Boolean Algebra", bullets: [
                        "AND ·  OR +  NOT. XOR is 1 iff inputs differ.",
                        "Identities: A+0=A, A·1=A, A+A'=1, A·A'=0, DeMorgan: (A+B)'=A'B'.",
                        "Simplify before expanding. ACSL answers are usually simplified expressions or 0/1.",
                        "Order: NOT, then AND, then OR — unless parentheses say otherwise."
                    ], diagram: "(A+B)' = A' · B'\n(A·B)' = A' + B'"),
                    SlideCard(title: "Stacks & Queues", bullets: [
                        "Stack: LIFO — push / pop / peek at the top.",
                        "Queue: FIFO — enqueue at back, dequeue from front.",
                        "Trace a sequence of operations; the answer is often the remaining contents left-to-right.",
                        "Python list: append/pop() is a stack; collections.deque is a queue."
                    ], diagram: "push A, push B, pop, push C\nStack top → C A"),
                    SlideCard(title: "Array Tracing", bullets: [
                        "0-based vs 1-based: ACSL Python traces are 0-based unless the stem says otherwise.",
                        "a[i] = a[i-1] + 1 mutates in place — later reads see new values.",
                        "Slicing a[1:4] does not include index 4.",
                        "Write the array after each statement; the printed join is the short-answer."
                    ], diagram: "a = [2, 4, 6]\na[1] = a[0] + a[2]\n# [2, 8, 6]")
                ],
                pythonPrompt: "Process a sequence of stack/queue commands from stdin and print the remaining items.",
                pythonTemplate: """
                from collections import deque
                import sys

                def run_commands(lines):
                    stack = []
                    queue = deque()
                    for raw in lines:
                        parts = raw.strip().split()
                        if not parts:
                            continue
                        cmd = parts[0].upper()
                        if cmd == "PUSH":
                            stack.append(parts[1])
                        elif cmd == "POP" and stack:
                            stack.pop()
                        elif cmd == "ENQ":
                            queue.append(parts[1])
                        elif cmd == "DEQ" and queue:
                            queue.popleft()
                    return " ".join(stack + list(queue))

                def solve() -> str:
                    lines = sys.stdin.read().strip().splitlines()
                    return run_commands(lines)

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "splitlines() keeps command order; strip() each line before split().",
                    "Return type is str here (space-separated). Do not return a list object.",
                    "Guard empty pop/dequeue — hidden tests may include extra POPs.",
                    "Match the spec print format exactly: spaces, no brackets."
                ],
                homework: """
                # Contest 3 homework
                # Trace PUSH A / PUSH B / POP / ENQ C / ENQ D / DEQ
                # Then implement with list + deque.

                from collections import deque
                import sys

                def simulate(text: str) -> str:
                    stack, q = [], deque()
                    for line in text.strip().splitlines():
                        p = line.strip().split()
                        if p[0] == "PUSH": stack.append(p[1])
                        elif p[0] == "POP" and stack: stack.pop()
                        elif p[0] == "ENQ": q.append(p[1])
                        elif p[0] == "DEQ" and q: q.popleft()
                    return " ".join(stack + list(q))

                if __name__ == "__main__":
                    print(simulate(sys.stdin.read()))
                """
            )
        default:
            return ContestSyllabus(
                contest: 4,
                title: "Contest 4 — Graph Matrices, Digital Electronics, Bit Shifts",
                topics: ["Graph Matrices", "Digital Electronics", "Bit Shifts"],
                slides: [
                    SlideCard(title: "Graph Matrices", bullets: [
                        "Adjacency matrix A[i][j] = 1 if an edge i→j exists (0 otherwise).",
                        "Undirected graphs are symmetric. Directed graphs need not be.",
                        "A² counts walks of length 2. Number of paths i→j of length k is (A^k)[i][j].",
                        "Degree of vertex i in an undirected graph = sum of row i."
                    ], diagram: "Vertices A B C\nA: 0 1 1\nB: 1 0 0\nC: 1 0 0"),
                    SlideCard(title: "Digital Electronics", bullets: [
                        "Gates: AND, OR, NOT, NAND, NOR, XOR, XNOR. Draw the circuit, then truth table.",
                        "NAND and NOR are universal — any circuit can be rebuilt from them.",
                        "Output of XOR is 1 iff inputs differ. XNOR is 1 iff they match.",
                        "ACSL may give a circuit in words: F = (A AND B) XOR C."
                    ], diagram: "A──AND──┐\nB──AND──XOR──F\nC────────┘"),
                    SlideCard(title: "Bit Shifts", bullets: [
                        "Left shift n << k multiplies by 2^k (in unbounded Python ints).",
                        "Right shift n >> k divides by 2^k (floor toward −∞ in Python).",
                        "ACSL bit-string shifts may be fixed width with 0-fill.",
                        "Combine with AND masks to extract fields (n & 0b111)."
                    ], diagram: "00010110 << 1 = 00101100\n00010110 >> 2 = 00000101")
                ],
                pythonPrompt: "Read n, then an n×n adjacency matrix, then two vertices. Print the number of walks of length 2.",
                pythonTemplate: """
                import sys

                def walks_length_2(matrix, u, v) -> int:
                    n = len(matrix)
                    total = 0
                    for k in range(n):
                        total += matrix[u][k] * matrix[k][v]
                    return total

                def solve() -> int:
                    tokens = sys.stdin.read().strip().split()
                    it = iter(tokens)
                    n = int(next(it))
                    matrix = [[int(next(it)) for _ in range(n)] for _ in range(n)]
                    u, v = int(next(it)), int(next(it))
                    return walks_length_2(matrix, u, v)

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "Flattened token scan (iter(tokens)) is the most reliable HackerRank pattern for grids.",
                    "Vertices may be 0-based in the sample — read the stem before subtracting 1.",
                    "Return an int count, not a float, even if you think of matrix multiply.",
                    "Do not print the whole matrix; hidden tests compare a single integer."
                ],
                homework: """
                # Contest 4 homework
                # Build A^2 by hand for a 3x3 undirected path graph, then code walks of length 2.

                import sys

                def walks2() -> int:
                    t = sys.stdin.read().strip().split()
                    it = iter(t)
                    n = int(next(it))
                    m = [[int(next(it)) for _ in range(n)] for _ in range(n)]
                    u, v = int(next(it)), int(next(it))
                    return sum(m[u][k] * m[k][v] for k in range(n))

                if __name__ == "__main__":
                    print(walks2())
                """
            )
        }
    }
}

private struct PresentationSlidesView: View {
    let syllabus: ContestSyllabus
    @State private var slideIndex = 0
    @Environment(\.teachingScale) private var scale
    @Environment(\.presentationModeEnabled) private var presentation

    var body: some View {
        let slides = syllabus.slides
        let index = min(max(slideIndex, 0), max(slides.count - 1, 0))
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("Previous") { slideIndex = max(0, index - 1) }
                    .disabled(index == 0)
                Text("Slide \(index + 1) of \(max(slides.count, 1))")
                    .font(.headline)
                    .frame(minWidth: 140)
                Button("Next") { slideIndex = min(slides.count - 1, index + 1) }
                    .disabled(index >= slides.count - 1)
                Spacer()
                Picker("Jump", selection: $slideIndex) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                        Text("\(i + 1). \(slide.title)").tag(i)
                    }
                }
                .frame(maxWidth: 420)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            if slides.isEmpty {
                Text("No slides loaded for this contest.")
                    .padding(24)
            } else {
                ScrollView {
                    slideCard(slides[index], number: index + 1, total: slides.count)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func slideCard(_ slide: SlideCard, number: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(number) / \(total)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(slide.title)
                .font(.system(size: 26 * scale, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(slide.bullets.enumerated()), id: \.offset) { _, bullet in
                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                        .font(.system(size: (presentation ? 20 : 16) * scale, weight: .bold))
                    Text(bullet)
                        .font(.system(size: (presentation ? 20 : 16) * scale))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !slide.diagram.isEmpty {
                Text(slide.diagram)
                    .font(.system(size: (presentation ? 18 : 14) * scale, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }

            if !slide.coachNote.isEmpty {
                Text("Coach script")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Text(slide.coachNote)
                    .font(.system(size: (presentation ? 18 : 15) * scale))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Sandboxes

private struct InteractiveSandboxView: View {
    let contest: Int

    var body: some View {
                ScrollView {
                    Group {
                        switch contest {
                        case 1: Contest1Sandbox()
                        case 2: Contest2Sandbox()
                        case 3: Contest3Sandbox()
                        default: Contest4Sandbox()
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct Contest1Sandbox: View {
    @State private var raw = "1A"
    @State private var fromBase = 16
    @State private var addA = "1011"
    @State private var addB = "0110"
    @State private var addBase = 2
    @State private var recKind = 0
    @State private var n = 4
    @State private var a = 7
    @State private var b = 3
    @Environment(\.teachingScale) private var scale

    private let recNames = [
        "f(0)=1, f(n)=n+f(n-1)",
        "f(0)=3, f(n)=2·f(n-1)−1",
        "f(0)=2, f(n)=n·f(n-1)+1"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Contest 1 live board")
                .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
            Text("Project this tab. Change the numeral, then point at the place-value expansion so Soha sees every power.")
                .font(.system(size: 13 * scale))
                .foregroundStyle(.secondary)

            GroupBox("1 · Converter + place value") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("numeral (e.g. 1A, 101101, 77)", text: $raw)
                    Picker("From base", selection: $fromBase) {
                        Text("2").tag(2)
                        Text("8").tag(8)
                        Text("10").tag(10)
                        Text("16").tag(16)
                    }
                    .pickerStyle(.segmented)
                    conversionRow("Decimal", String(converted))
                    conversionRow("Binary", String(converted, radix: 2))
                    conversionRow("Octal", String(converted, radix: 8))
                    conversionRow("Hex", String(converted, radix: 16).uppercased())
                    Text(placeValueExpansion)
                        .font(.system(size: 13 * scale, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            GroupBox("2 · Add in a base") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("addend A", text: $addA)
                        TextField("addend B", text: $addB)
                    }
                    Picker("Base", selection: $addBase) {
                        Text("2").tag(2)
                        Text("8").tag(8)
                        Text("16").tag(16)
                    }
                    .pickerStyle(.segmented)
                    Text(addInBase)
                        .font(.system(size: 14 * scale, design: .monospaced))
                }
            }

            GroupBox("3 · Recursion table") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Definition", selection: $recKind) {
                        ForEach(0..<recNames.count, id: \.self) { Text(recNames[$0]).tag($0) }
                    }
                    Stepper("n = \(n)", value: $n, in: 0...10)
                    Text(recursionTable(kind: recKind, n: n))
                        .font(.system(size: 13 * scale, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            GroupBox("4 · Branch tracer  if a>b: a=a-b  else: b=b-a  print(a,b)") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper("a = \(a)", value: $a, in: 0...20)
                    Stepper("b = \(b)", value: $b, in: 0...20)
                    Text(branchTrace(a: a, b: b))
                        .font(.system(size: 14 * scale, design: .monospaced))
                }
            }
        }
        .font(.system(size: 16 * scale, design: .monospaced))
    }

    private var converted: Int {
        Int(raw.trimmingCharacters(in: .whitespacesAndNewlines), radix: fromBase) ?? 0
    }

    private var placeValueExpansion: String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let parsed = Int(s, radix: fromBase) else {
            return "Could not parse \(s) as base \(fromBase)."
        }
        var terms: [String] = []
        for (i, ch) in s.reversed().enumerated() {
            let d = Int(String(ch), radix: fromBase) ?? 0
            let p = intPow(fromBase, i)
            terms.append("\(ch)×\(fromBase)^\(i)=\(d * p)")
        }
        return terms.reversed().joined(separator: " + ") + " = \(parsed)₁₀"
    }

    private var addInBase: String {
        let x = Int(addA.trimmingCharacters(in: .whitespacesAndNewlines), radix: addBase)
        let y = Int(addB.trimmingCharacters(in: .whitespacesAndNewlines), radix: addBase)
        guard let x, let y else { return "Parse error — check digits for base \(addBase)." }
        let sum = x + y
        let shown = String(sum, radix: addBase).uppercased()
        return "\(addA)₍\(addBase)₎ + \(addB)₍\(addBase)₎ = \(shown)₍\(addBase)₎  (decimal \(x)+\(y)=\(sum))"
    }

    private func conversionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
            Text(value)
        }
    }

    private func recursionTable(kind: Int, n: Int) -> String {
        var lines = [" n | f(n)"]
        var prev = 0
        for k in 0...n {
            let val: Int
            switch kind {
            case 1:
                val = k == 0 ? 3 : 2 * prev - 1
            case 2:
                val = k == 0 ? 2 : k * prev + 1
            default:
                val = k == 0 ? 1 : k + prev
            }
            lines.append(String(format: "%2d | %d", k, val))
            prev = val
        }
        lines.append("Asked f(\(n)) = \(prev)")
        return lines.joined(separator: "\n")
    }

    private func branchTrace(a startA: Int, b startB: Int) -> String {
        var a = startA
        var b = startB
        var log = ["start a=\(a) b=\(b)"]
        if a > b {
            log.append("\(a) > \(b) True → take IF, skip else")
            a = a - b
            log.append("a = a-b → \(a)")
        } else {
            log.append("\(a) > \(b) False → skip IF, take ELSE")
            b = b - a
            log.append("b = b-a → \(b)")
        }
        log.append("print → \(a) \(b)")
        return log.joined(separator: "\n")
    }

    private func intPow(_ base: Int, _ exp: Int) -> Int {
        var r = 1
        for _ in 0..<exp { r *= base }
        return r
    }
}

private struct Contest2Sandbox: View {
    @State private var postfix = "3 4 + 5 *"
    @State private var bitsA = "1011"
    @State private var bitsB = "1101"
    @State private var loopN = 4
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Postfix stack simulator")
                .font(.system(size: 20 * scale, weight: .semibold))
            TextField("postfix tokens", text: $postfix)
            Text(evalPostfix(postfix))
                .font(.system(size: 14 * scale, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

            Text("Bit flicking")
                .font(.headline)
            HStack {
                TextField("A", text: $bitsA)
                TextField("B", text: $bitsB)
            }
            bitRows
                .font(.system(size: 16 * scale, design: .monospaced))

            Text("Loop tracing · s += i for i in 1..n")
                .font(.headline)
            Stepper("n = \(loopN)", value: $loopN, in: 1...10)
            Text(loopTrace(loopN))
                .font(.system(size: 13 * scale, design: .monospaced))
        }
    }

    private var bitRows: some View {
        let a = parseBits(bitsA)
        let b = parseBits(bitsB)
        let width = max(bitsA.count, 1)
        return VStack(alignment: .leading, spacing: 4) {
            Text("AND  \(formatBits(a & b, width: width))")
            Text("OR   \(formatBits(a | b, width: width))")
            Text("XOR  \(formatBits(a ^ b, width: width))")
            Text("NOT A \(formatBits(~a & mask(width), width: width))")
            Text("LSHIFT A \(formatBits((a << 1) & mask(width), width: width))")
            Text("RSHIFT A \(formatBits(a >> 1, width: width))")
        }
    }

    private func parseBits(_ s: String) -> Int {
        Int(s.filter { $0 == "0" || $0 == "1" }, radix: 2) ?? 0
    }

    private func mask(_ w: Int) -> Int { (1 << max(w, 1)) - 1 }

    private func formatBits(_ n: Int, width: Int) -> String {
        let w = max(width, 1)
        let bin = String(n & mask(w), radix: 2)
        return String(repeating: "0", count: max(0, w - bin.count)) + bin
    }

    private func evalPostfix(_ expr: String) -> String {
        var stack: [Int] = []
        var log: [String] = ["start []"]
        for tok in expr.split(separator: " ").map(String.init) {
            if "+-*".contains(tok), stack.count >= 2 {
                let b = stack.removeLast()
                let a = stack.removeLast()
                let r = tok == "+" ? a + b : tok == "-" ? a - b : a * b
                stack.append(r)
                log.append("\(tok) on \(a),\(b) → \(stack)")
            } else if let v = Int(tok) {
                stack.append(v)
                log.append("push \(v) → \(stack)")
            } else {
                log.append("skip \(tok)")
            }
        }
        log.append("result \(stack.last.map(String.init) ?? "empty")")
        return log.joined(separator: "\n")
    }

    private func loopTrace(_ n: Int) -> String {
        var s = 0
        var lines = ["i  s"]
        for i in 1...n {
            s += i
            lines.append("\(i)  \(s)")
        }
        return lines.joined(separator: "\n")
    }
}

private struct Contest3Sandbox: View {
    @State private var a = false
    @State private var b = false
    @State private var stackText = "A,B"
    @State private var queueText = "X"
    @State private var command = "POP"
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Logic gate truth table")
                .font(.system(size: 20 * scale, weight: .semibold))
            Toggle("A", isOn: $a)
            Toggle("B", isOn: $b)
            let av = a ? 1 : 0
            let bv = b ? 1 : 0
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow { Text("AND"); Text("\(av & bv)") }
                GridRow { Text("OR"); Text("\(av | bv)") }
                GridRow { Text("XOR"); Text("\(av ^ bv)") }
                GridRow { Text("NAND"); Text("\((av & bv) == 0 ? 1 : 0)") }
                GridRow { Text("NOR"); Text("\((av | bv) == 0 ? 1 : 0)") }
                GridRow { Text("NOT A"); Text("\(1 - av)") }
            }
            .font(.system(size: 16 * scale, design: .monospaced))

            Divider()
            Text("Stack / queue simulator")
                .font(.headline)
            Text("Stack (top is right): \(stackText)")
            Text("Queue (front is left): \(queueText)")
            Picker("Command", selection: $command) {
                ForEach(["PUSH C", "POP", "ENQ Y", "DEQ"], id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            Button("Apply to class demo") { apply() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func apply() {
        var stack = stackText.split(separator: ",").map(String.init).filter { !$0.isEmpty }
        var queue = queueText.split(separator: ",").map(String.init).filter { !$0.isEmpty }
        switch command {
        case "PUSH C": stack.append("C")
        case "POP":
            if !stack.isEmpty { stack.removeLast() }
        case "ENQ Y": queue.append("Y")
        case "DEQ":
            if !queue.isEmpty { queue.removeFirst() }
        default: break
        }
        stackText = stack.joined(separator: ",")
        queueText = queue.joined(separator: ",")
    }
}

private struct Contest4Sandbox: View {
    @State private var matrix: [[Int]] = [
        [0, 1, 1, 0],
        [1, 0, 0, 1],
        [1, 0, 0, 1],
        [0, 1, 1, 0]
    ]
    @State private var bitValue = 22
    @State private var shift = 1
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Graph adjacency matrix (click to toggle edge)")
                .font(.system(size: 20 * scale, weight: .semibold))
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<4, id: \.self) { r in
                    GridRow {
                        ForEach(0..<4, id: \.self) { c in
                            Button {
                                matrix[r][c] = matrix[r][c] == 0 ? 1 : 0
                            } label: {
                                Text("\(matrix[r][c])")
                                    .frame(width: 36, height: 36)
                                    .background(matrix[r][c] == 1 ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            Text("Walks of length 2 from 0 to 1: \(walks(from: 0, to: 1))")
                .font(.system(size: 16 * scale, design: .monospaced))

            Divider()
            Text("Digital electronics · F = (A AND B) XOR C")
                .font(.headline)
            DigitalCircuitDemo()

            Divider()
            Text("Bit shifts (8-bit window)")
                .font(.headline)
            Stepper("value = \(bitValue)  (\(eight(bitValue)))", value: $bitValue, in: 0...255)
            Stepper("shift k = \(shift)", value: $shift, in: 0...7)
            Text("<<  \(eight((bitValue << shift) & 255))")
            Text(">>  \(eight(bitValue >> shift))")
                .font(.system(size: 16 * scale, design: .monospaced))
        }
    }

    private func walks(from u: Int, to v: Int) -> Int {
        (0..<4).reduce(0) { $0 + matrix[u][$1] * matrix[$1][v] }
    }

    private func eight(_ n: Int) -> String {
        let bin = String(n & 255, radix: 2)
        return String(repeating: "0", count: max(0, 8 - bin.count)) + bin
    }
}

private struct DigitalCircuitDemo: View {
    @State private var a = true
    @State private var b = false
    @State private var c = true
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("A", isOn: $a)
            Toggle("B", isOn: $b)
            Toggle("C", isOn: $c)
            let andAB = a && b
            let f = andAB != c
            Text("A AND B = \(andAB ? 1 : 0)")
            Text("F = (A AND B) XOR C = \(f ? 1 : 0)")
                .font(.system(size: 18 * scale, weight: .bold, design: .monospaced))
        }
    }
}

// MARK: - Python HackerRank simulator

private struct PythonHackerRankSimulatorView: View {
    let contest: Int
    let studentName: String
    @State private var copied = false
    @Environment(\.teachingScale) private var scale
    @Environment(\.presentationModeEnabled) private var presentation

    var body: some View {
        let syllabus = ContestCurriculum.syllabus(for: contest)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("HackerRank I/O for \(studentName)")
                    .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                Text(syllabus.pythonPrompt)
                    .font(.system(size: 15 * scale))
                    .foregroundStyle(.secondary)

                GroupBox("How hidden tests send data") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. stdin is a raw text stream — no prompts, no teacher sitting there.")
                        Text("2. Tokenize:  line = input().strip(); parts = line.split()")
                        Text("3. Or slurp:  tokens = sys.stdin.read().strip().split()")
                        Text("4. Convert:  n = int(parts[0])  — never leave numbers as strings if the spec wants int.")
                        Text("5. Print only the required return value. Extra text fails hidden cases.")
                    }
                    .font(.system(size: (presentation ? 16 : 13) * scale))
                }

                GroupBox("Exact function contract") {
                    Text(syllabus.pythonTemplate)
                        .font(.system(size: (presentation ? 15 : 12) * scale, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(syllabus.pythonNotes, id: \.self) { note in
                        Text("• \(note)")
                            .font(.system(size: 13 * scale))
                    }
                }

                HStack {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(syllabus.homework, forType: .string)
                        copied = true
                    } label: {
                        Label(copied ? "Homework copied" : "Copy homework to clipboard", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.borderedProminent)
                    Text("Students paste into a .py file and submit on HackerRank-style graders.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GroupBox("Homework source") {
                    Text(syllabus.homework)
                        .font(.system(size: (presentation ? 15 : 12) * scale, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Mock exams

private struct TeamMockExamsView: View {
    let selectedStudentName: String
    @Binding var revealKeys: Bool
    @State private var contestPick = 1
    @State private var responses: [String] = Array(repeating: "", count: 5)
    @Environment(\.teachingScale) private var scale

    var body: some View {
        let exam = Self.exams[contestPick - 1]
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Team mock · 5 short-answer questions")
                        .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                    Text("Focus student: \(selectedStudentName). Programming (5 pts) is scored separately on hidden tests.")
                        .font(.system(size: 13 * scale))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Round", selection: $contestPick) {
                    ForEach(1...4, id: \.self) { Text("Contest \($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                .onChange(of: contestPick) { _, _ in
                    responses = Array(repeating: "", count: 5)
                }
            }
            .padding(16)

            HStack {
                Button(revealKeys ? "Hide solution keys" : "Reveal Solution Keys") {
                    revealKeys.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                Text("Coach override — project derivations for whole-team review")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Short-answer score preview: \(score(exam))/5")
                    .font(.headline.monospaced())
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(exam.questions.enumerated()), id: \.offset) { idx, q in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Q\(idx + 1). \(q.prompt)")
                                .font(.system(size: 15 * scale, weight: .semibold))
                            TextField("Answer", text: $responses[idx])
                                .textFieldStyle(.roundedBorder)
                            if revealKeys {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Key: \(q.answer)")
                                        .font(.system(size: 14 * scale, weight: .bold, design: .monospaced))
                                    Text(q.derivation)
                                        .font(.system(size: 13 * scale))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
            }
        }
    }

    private func score(_ exam: MockExam) -> Int {
        zip(responses, exam.questions).reduce(0) { acc, pair in
            acc + (normalize(pair.0) == normalize(pair.1.answer) ? 1 : 0)
        }
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private static let exams: [MockExam] = [
        MockExam(contest: 1, title: "Contest 1", questions: [
            MockQuestion(prompt: "Convert 1A16 to decimal.", answer: "26",
                         derivation: "1×16 + 10 = 16+10 = 26. Python: int('1A', 16)."),
            MockQuestion(prompt: "Convert 1011012 to octal.", answer: "55",
                         derivation: "Group bits by 3 from the right: 101 1012 = 5 58 → 558."),
            MockQuestion(prompt: "f(0)=1, f(n)=n+f(n-1). Find f(4).", answer: "11",
                         derivation: "f(1)=2, f(2)=4, f(3)=7, f(4)=11. Unwind the recursion; do not guess n!."),
            MockQuestion(prompt: "After: a,b=7,3; if a>b: a=a-b else: b=b-a. Print a,b.", answer: "4,3",
                         derivation: "7>3 true so a=4. Branch tracing: only the true arm runs. Output 4 3."),
            MockQuestion(prompt: "int('77', 8) in Python equals?", answer: "63",
                         derivation: "7×8+7=63. Hidden tests: parse tokens then int(s, base).")
        ]),
        MockExam(contest: 2, title: "Contest 2", questions: [
            MockQuestion(prompt: "Evaluate postfix: 3 4 + 5 *", answer: "35",
                         derivation: "Stack: [3] [3,4] pop 4,3 → 7; push 7; push 5; 7*5=35."),
            MockQuestion(prompt: "Prefix * + 2 3 4 equals?", answer: "20",
                         derivation: "* applied to (+ 2 3) and 4 → (5)*4=20."),
            MockQuestion(prompt: "1011 AND 1101 (binary, 4 bits)", answer: "1001",
                         derivation: "Bitwise AND: 1∧1=1, 0∧1=0, 1∧0=0, 1∧1=1 → 1001."),
            MockQuestion(prompt: "LSHIFT of 1011 (4-bit, 0-fill)", answer: "0110",
                         derivation: "Shift left, drop leftmost 1, fill 0 on right → 0110."),
            MockQuestion(prompt: "s=0; for i in range(1,5): s+=i. Final s?", answer: "10",
                         derivation: "range(1,5) is 1,2,3,4. Sum=10. Exclusive end is the usual Python trap.")
        ]),
        MockExam(contest: 3, title: "Contest 3", questions: [
            MockQuestion(prompt: "Simplify (A+B)' using DeMorgan.", answer: "A'B'",
                         derivation: "(A+B)' = A' · B'. Coach: write the dual (AB)' = A'+B' beside it."),
            MockQuestion(prompt: "A=1, B=0. A XOR B?", answer: "1",
                         derivation: "XOR is 1 iff inputs differ. Truth table row (1,0) → 1."),
            MockQuestion(prompt: "Stack: PUSH A, PUSH B, POP, PUSH C. Top to bottom (top first)?", answer: "C,A",
                         derivation: "After pop, stack is [A]; push C → [A,C], top=C."),
            MockQuestion(prompt: "Queue ENQ X, ENQ Y, DEQ. Front item?", answer: "Y",
                         derivation: "FIFO: X then Y; dequeue removes X; front is Y."),
            MockQuestion(prompt: "a=[2,4,6]; a[1]=a[0]+a[2]; a is?", answer: "[2,8,6]",
                         derivation: "Index 1 becomes 2+6=8. In-place mutation; later reads see 8.")
        ]),
        MockExam(contest: 4, title: "Contest 4", questions: [
            MockQuestion(prompt: "Undirected edge 0-1 and 1-2. A[0][2] in adjacency matrix?", answer: "0",
                         derivation: "No direct 0-2 edge. Walks of length 2 exist via 1, counted in A² not A."),
            MockQuestion(prompt: "For A with A01=A10=A12=A21=1 else 0, (A²)[0][2]?", answer: "1",
                         derivation: "Sum_k A[0][k]A[k][2] = A[0][1]A[1][2]=1. One walk of length 2."),
            MockQuestion(prompt: "A=1,B=1,C=0. F=(A AND B) XOR C", answer: "1",
                         derivation: "AND=1; 1 XOR 0=1. Draw the two-gate circuit on the projector."),
            MockQuestion(prompt: "8-bit 00010110 left-shifted 1?", answer: "00101100",
                         derivation: "Drop/shift left, 0-fill. 22<<1 = 44 = 001011002."),
            MockQuestion(prompt: "n=22; n>>2 in Python?", answer: "5",
                         derivation: "22//4 = 5. Right shift by k is floor-divide by 2^k for non-negative n.")
        ])
    ]
}

#Preview("ACSL Junior Coach") {
    ACSLJuniorCoachRootView()
        .frame(width: 1200, height: 800)
}
