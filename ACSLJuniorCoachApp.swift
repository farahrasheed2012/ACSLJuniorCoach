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
                roleNote: "Focus student · strong on theory, building HackerRank I/O",
                scores: [
                    RoundScore(shortAnswer: 4, programming: 4),
                    RoundScore(shortAnswer: 5, programming: 3),
                    RoundScore(shortAnswer: 3, programming: 4),
                    RoundScore(shortAnswer: 0, programming: 0)
                ]
            ),
            TeamStudent(
                id: UUID(),
                name: "Alex",
                roleNote: "Fast tracer · watch bit-flicking operator order",
                scores: [
                    RoundScore(shortAnswer: 5, programming: 5),
                    RoundScore(shortAnswer: 4, programming: 5),
                    RoundScore(shortAnswer: 4, programming: 4),
                    RoundScore(shortAnswer: 3, programming: 2)
                ]
            ),
            TeamStudent(
                id: UUID(),
                name: "Maya",
                roleNote: "Boolean algebra lead · graph matrices next",
                scores: [
                    RoundScore(shortAnswer: 3, programming: 4),
                    RoundScore(shortAnswer: 3, programming: 3),
                    RoundScore(shortAnswer: 5, programming: 4),
                    RoundScore(shortAnswer: 2, programming: 3)
                ]
            ),
            TeamStudent(
                id: UUID(),
                name: "Liam",
                roleNote: "Python first · needs number-base conversions",
                scores: [
                    RoundScore(shortAnswer: 2, programming: 5),
                    RoundScore(shortAnswer: 2, programming: 4),
                    RoundScore(shortAnswer: 1, programming: 3),
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
                    Text("Teaching \(selectedStudentName) and the team · \(syllabus.topics.joined(separator: " · "))")
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
                    SlideCard(title: "Number Systems", bullets: [
                        "Bases you must convert: binary (2), octal (8), decimal (10), hexadecimal (16).",
                        "Place value: digit × base^position. Example: 1A16 = 1×16 + 10 = 2610.",
                        "Shortcuts: 3 binary digits = 1 octal digit; 4 binary digits = 1 hex digit.",
                        "Watch ACSL notation: trailing subscripts name the base (10112, 178, 2F16)."
                    ], diagram: "10112 → group by 4 → B16\n178 → 1×8+7 = 1510 → F16"),
                    SlideCard(title: "Recursion", bullets: [
                        "A recursive function calls itself on a smaller input until a base case.",
                        "Always identify: (1) base case, (2) recursive case, (3) what is returned.",
                        "Evaluate from the inside out: f(3) needs f(2) needs f(1), then unwind.",
                        "ACSL often uses piecewise definitions: f(n) = n + f(n−1), f(0)=1."
                    ], diagram: "f(3)\n └─ 3 + f(2)\n      └─ 2 + f(1)\n           └─ 1 + f(0)=1"),
                    SlideCard(title: "Branch Tracing (WDTTPD)", bullets: [
                        "Trace if / elif / else exactly as written. Indentation is the structure.",
                        "Track each variable after every assignment. Never skip a branch mentally.",
                        "Boolean conditions: == vs = ; and/or short-circuit in Python.",
                        "Final printed value (or returned value) is the short-answer."
                    ], diagram: "if a > b: a = a - b\nelse: b = b - a\nprint(a, b)")
                ],
                pythonPrompt: "Read two tokens. Convert the first numeral from the given base to decimal, then print it.",
                pythonTemplate: """
                import sys

                def to_decimal(value: str, base: int) -> int:
                    return int(value.strip(), base)

                def solve() -> int:
                    data = sys.stdin.read().strip().split()
                    numeral, base_s = data[0], data[1]
                    return to_decimal(numeral, int(base_s))

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "Never use input('prompt:') — hidden tests only see stdout of the answer.",
                    "input().strip().split() tokenizes a line; sys.stdin.read().split() grabs all tokens.",
                    "int(s, base) is the Python converter ACSL problems expect you to know.",
                    "Return type must match the spec: int vs str. print() adds a newline HackerRank accepts."
                ],
                homework: """
                # Contest 1 homework — due before next practice
                # 1) Convert 2F16, 778, and 1101102 to decimal on paper, then verify with int().
                # 2) Trace f(5) where f(0)=2 and f(n)=n*f(n-1)+1.
                # 3) HackerRank drill: parse "A 16" and print 10.

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
    @Environment(\.teachingScale) private var scale
    @Environment(\.presentationModeEnabled) private var presentation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(syllabus.slides.enumerated()), id: \.offset) { index, slide in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Slide \(index + 1) · \(slide.title)")
                            .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                        ForEach(slide.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(bullet)
                                    .font(.system(size: (presentation ? 18 : 14) * scale))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Text(slide.diagram)
                            .font(.system(size: (presentation ? 16 : 13) * scale, weight: .medium, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
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
        }
    }
}

private struct Contest1Sandbox: View {
    @State private var raw = "1A"
    @State private var fromBase = 16
    @State private var n = 4
    @Environment(\.teachingScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Live converters")
                .font(.system(size: 20 * scale, weight: .semibold))

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Numeral")
                    TextField("value", text: $raw)
                    Picker("From base", selection: $fromBase) {
                        Text("2").tag(2)
                        Text("8").tag(8)
                        Text("10").tag(10)
                        Text("16").tag(16)
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: 280)

                VStack(alignment: .leading, spacing: 6) {
                    conversionRow("Decimal", String(converted))
                    conversionRow("Binary", String(converted, radix: 2))
                    conversionRow("Octal", String(converted, radix: 8))
                    conversionRow("Hex", String(converted, radix: 16).uppercased())
                }
                .font(.system(size: 16 * scale, design: .monospaced))
            }

            Divider()
            Text("Recursion unwind · f(n) = n + f(n−1), f(0)=1")
                .font(.headline)
            Stepper("n = \(n)", value: $n, in: 0...8)
            Text(recursionTrace(n))
                .font(.system(size: 14 * scale, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var converted: Int {
        Int(raw.trimmingCharacters(in: .whitespacesAndNewlines), radix: fromBase) ?? 0
    }

    private func conversionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
            Text(value)
        }
    }

    private func recursionTrace(_ n: Int) -> String {
        func f(_ k: Int) -> Int { k == 0 ? 1 : k + f(k - 1) }
        var lines = (0...n).map { "f(\($0)) = \(f($0))" }
        lines.append("Call stack: " + (0...n).reversed().map { "f(\($0))" }.joined(separator: " → "))
        return lines.joined(separator: "\n")
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
