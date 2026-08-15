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
                contest1EightWeekPlan
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

    private var contest1EightWeekPlan: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contest 1 · 8-week plan (Monday Aug 17 → Oct 11, 2026)")
                .font(.system(size: 18 * scale, weight: .semibold))
            Text("One meeting per week, 1.5 hours. Homework about 1 hour before the next meeting (30 min paper + 30 min Python). Jump to “Week N” in Contest 1 slides.")
                .font(.system(size: 13 * scale))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 6) {
                weekRow("1", "Aug 17", "First Python: print, strings, variables, errors")
                weekRow("2", "Aug 24", "Place value and four bases; int() / int(s, base)")
                weekRow("3", "Aug 31", "To binary/hex/octal; grouping; adding in a base")
                weekRow("4", "Sep 7", "split(); conversion program; numbers checkpoint")
                weekRow("5", "Sep 14", "Recursion tables; def f(n); return vs print")
                weekRow("6", "Sep 21", "Harder recursion: second rule, even/odd, two-arg grid")
                weekRow("7", "Sep 28", "If/elif/else on paper and in Python")
                weekRow("8", "Oct 5", "Mock short-answer + hidden-test hygiene; contest checklist")
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func weekRow(_ n: String, _ date: String, _ focus: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("W\(n)")
                .font(.system(size: 13 * scale, weight: .bold, design: .monospaced))
                .frame(width: 28, alignment: .leading)
            Text(date)
                .font(.system(size: 12 * scale, design: .monospaced))
                .frame(width: 56, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(focus)
                .font(.system(size: 13 * scale))
                .fixedSize(horizontal: false, vertical: true)
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
                        title: "Welcome — what Contest 1 is (middle school version)",
                        bullets: [
                            "ACSL Junior Contest 1 is three skills. That is the whole test. Nothing else sneaks in.",
                            "Skill 1: Number systems. Same idea as hundreds-tens-ones, but the ‘bundle size’ can be 2, 8, 10, or 16 instead of 10.",
                            "Skill 2: Recursion. A recipe that says ‘use a smaller version of me’ until a stopping rule.",
                            "Skill 3: Branch tracing. Follow an if/else program like a choose-your-own-adventure. Never skip lines. Never guess.",
                            "You will also write a short Python program. The computer types the input for you. You must print only the answer.",
                            "We meet once a week for 1.5 hours, plus about 1 hour of homework. Eight weeks, starting Monday August 17.",
                            "Goal today: convert a number on paper AND in Python, fill a recursion table AND write def f(n), trace an if-program AND run it."
                        ],
                        diagram: "Short-answer: 5 questions  (about 1 point each)   max 5\nProgramming: hidden tests                        max 5\nTogether this contest:                            max 10",
                        coachNote: "Say this slowly: we are not learning ‘all of computer science.’ We are learning three contest tricks. Write NUMBER SYSTEMS / RECURSION / IF-ELSE on the board and leave them up."
                    ),
                    SlideCard(
                        title: "8-week plan · one 1.5-hour meeting + 1 hour homework",
                        bullets: [
                            "We meet once a week for 90 minutes, starting Monday August 17, 2026. Eight meetings. Last meeting October 5. Ready by October 11.",
                            "Clock in the room: 0:00–0:15 homework check. 0:15–0:55 new paper teaching. 0:55–1:25 Python lab (type the gray boxes). 1:25–1:30 assign homework.",
                            "Homework is about 1 hour before the next meeting: 30 minutes paper, 30 minutes typing. Paper first. No new topics on homework.",
                            "If lab time is shaky, we repeat that week’s lab next meeting instead of pushing ahead.",
                            "Jump menu: titles that start with Week N. Stay inside that week during the meeting."
                        ],
                        diagram: "Week 1  Aug 17   First Python\\nWeek 2  Aug 24   Bases + int()\\nWeek 3  Aug 31   Remainders, grouping, adding\\nWeek 4  Sep  7   I/O program + numbers checkpoint\\nWeek 5  Sep 14   Recursion tables + def f\\nWeek 6  Sep 21   Harder recursion\\nWeek 7  Sep 28   If/else paper and Python\\nWeek 8  Oct  5   Mock + contest checklist",
                        coachNote: "Put this slide on the projector at the start of every meeting for 30 seconds so Soha sees where we are."
                    ),
                    SlideCard(
                        title: "Week 1 · Aug 17 · meeting (90 min) · first Python",
                        bullets: [
                            "0:00–0:15  Names, what ACSL Contest 1 is (three skills), install/open a place to run Python.",
                            "0:15–0:40  print, quotes vs math, variables. Type every gray box together. Do not skip the 6-line program.",
                            "0:40–0:55  Errors as messages. Break a quote on purpose. Read the line number.",
                            "0:55–1:25  Lab: retype the 6-line program from a blank file. Then print 3+4, print('3+4'), n=10, n=n+5.",
                            "1:25–1:30  Assign Week 1 homework (next slide). Confirm Soha can run a file at home."
                        ],
                        diagram: "Success tonight:\\n  print(3 + 4) shows 7\\n  can say why '7'+'1' is 71 not 8\\n  6-line program matches expected output",
                        coachNote: "Do not start hex tonight. If Python is not running by 0:40, spend the rest of lab on print only."
                    ),
                    SlideCard(
                        title: "Python we need today (first time? start here)",
                        bullets: [
                            "Python is a language for giving a computer a list of instructions. We will use a tiny piece of it — not the whole language.",
                            "You type in a text file that ends in .py (or in this app’s Python tab). Then you RUN it. Running means: ‘computer, do these lines now.’",
                            "The computer is obedient and literal. It does not guess. If you forget a quote or a colon, it stops and shows an error. That is normal, not a fail.",
                            "Today’s only toolbox: print, numbers vs text, a named box (variable), int() to turn text into a number, input to read a line, if/else, and later one function named f.",
                            "We will type small programs together. Copy the gray box exactly the first time — including quotes and parentheses."
                        ],
                        diagram: "A program is a recipe:\n  1. You write the steps.\n  2. You press Run.\n  3. Output appears (what print shows).\n\nYou do NOT need: websites, robots, or ‘AI’.\nYou DO need: careful typing and reading errors.",
                        coachNote: "If this is Soha’s first Python day, stay on the next few slides until print(3+4) works on her machine. Do not rush to int('1A',16) until print works."
                    ),
                    SlideCard(
                        title: "Python: print() — this is how the computer talks back",
                        bullets: [
                            "print(...) shows something on the screen. That screen output is what ACSL’s hidden tests read.",
                            "Parentheses are required: print(7) not print 7.",
                            "You can print a number: print(7). You can print a calculation: print(3 + 4) which shows 7.",
                            "You can print text if you wrap it in quotes: print('hello') shows hello.",
                            "Each print goes on its own line. Two print lines → two lines of output.",
                            "Type this first program with the class before anything else."
                        ],
                        diagram: "print(7)\nprint(3 + 4)\nprint('hello')\nprint('3 + 4')\n\nWhat you should see:\n7\n7\nhello\n3 + 4\n\nNotice: quotes around 3 + 4 print the CHARACTERS, they do not add.",
                        coachNote: "Ask before running the last line: ‘Will this print 7 or the symbols 3 + 4?’ Wait for ‘the symbols.’ Then run."
                    ),
                    SlideCard(
                        title: "Python: quotes = text (a string). No quotes = math.",
                        bullets: [
                            "Anything in single quotes 'like this' or double quotes \"like this\" is a STRING: a chain of characters.",
                            "'7' is the character seven. 7 is the number seven. They look similar to humans. They are different to Python.",
                            "Numbers can do math: 7 + 1 is 8. Strings glue: '7' + '1' is '71'.",
                            "Spaces inside quotes count. 'hi' and ' hi' are different.",
                            "Most ACSL input arrives as strings. That is why we later use int(...) to turn '16' into 16."
                        ],
                        diagram: "print(10 + 2)      # 12     math\nprint('10' + '2')   # 102    glued text\nprint('A')          # A      a letter\nprint(A)            # ERROR  Python thinks A is a missing name\n\nRule: letters used as hex digits must be in quotes: '1A'",
                        coachNote: "The print(A) error is a gift. Show NameError: name 'A' is not defined. They will see this the first time they type 1A without quotes."
                    ),
                    SlideCard(
                        title: "Python: a named box (variable) — your first assignment",
                        bullets: [
                            "A variable is a labeled box. n = 7 means: make a box called n and put 7 in it.",
                            "The name goes on the LEFT of =. The value goes on the RIGHT. Read it as ‘n gets 7.’",
                            "Later, print(n) shows whatever is in the box right now.",
                            "You can change the box: n = n + 1 means ‘take what’s in n, add 1, put it back.’",
                            "Names must start with a letter. Use short names: n, a, b, parts. Do not use spaces in names.",
                            "Python is case-sensitive: N and n are different boxes."
                        ],
                        diagram: "n = 7\nprint(n)       # 7\nn = n + 1\nprint(n)       # 8\n\nmessage = 'hi'\nprint(message) # hi\n\n# Wrong:\n7 = n          # cannot put a box into a number",
                        coachNote: "Have them point at the box: ‘What is in n after two lines?’ Fingers before they run."
                    ),
                    SlideCard(
                        title: "Python: type this 6-line first program together",
                        bullets: [
                            "Do not skip this. First-time students need a win that is only print and a box.",
                            "Type every symbol: parentheses, quotes, equals.",
                            "Then RUN. Compare your screen to the expected output in the gray box.",
                            "If nothing happens, you did not run. If a red error appears, read the next slide — do not delete the whole file."
                        ],
                        diagram: "print('I am learning Python')\nprint(3 + 4)\nn = 10\nprint(n)\nn = n + 5\nprint(n)\n\nExpected output:\nI am learning Python\n7\n10\n15",
                        coachNote: "Walk the room. The usual bugs: Print with a capital P, missing quotes, missing parentheses, using – instead of -."
                    ),
                    SlideCard(
                        title: "Python: errors are messages, not a report card",
                        bullets: [
                            "A red error means Python could not follow a line. It usually names the line number. Read that line first.",
                            "SyntaxError: you forgot a quote, parenthesis, or colon. Count them in pairs ( ) and ' '.",
                            "NameError: you used a name you never created, or a letter that needed quotes (print(A) instead of print('A')).",
                            "IndentationError: spaces at the start of the line are wrong. For these first programs, start every line at the left edge (no spaces yet).",
                            "TypeError: you mixed text and numbers, like '7' + 1. Put int() around the text, or quotes around both sides on purpose.",
                            "Fix one thing, run again. Do not rewrite from scratch."
                        ],
                        diagram: "print('hello)     SyntaxError  (missing quote)\nprint(hello)      NameError     (hello is not a box; use 'hello')\n print(7)         IndentationError if that leading space is accidental\n'7' + 1           TypeError     (text + number)\n\nint('7') + 1      # 8   this is the fix for the last one",
                        coachNote: "Project a real error. Have the class find the line number together. Normalize: every programmer sees errors all day."
                    ),
                    SlideCard(
                        title: "Python: # comments, blank lines, and matching punctuation",
                        bullets: [
                            "Anything after # on a line is a comment. Python skips it. Write comments for humans.",
                            "Blank lines are fine. They do not change the program. Use them to breathe.",
                            "Parentheses come in pairs: print(7)  — open and close.",
                            "Quotes come in pairs: 'hello'. If you start with ' you must end with ' (not a curly Word-doc quote).",
                            "Do not copy from a Google Doc that turns quotes into “smart quotes.” Type quotes on the keyboard.",
                            "We are now ready for number systems on paper — then we will come back and use int()."
                        ],
                        diagram: "# This line is ignored.\nprint(3 + 4)   # this part runs; the note does not\n\n# Keyboard quotes:   '  and  \"\n# Avoid:             ’  “  ”   (pretty quotes from slides/docs)\n\nprint('1A')    # good\nprint(int('1A', 16))  # later today: this prints 26",
                        coachNote: "If paste-from-slides breaks, have them retype quotes. Then continue to place value. int('1A',16) waits until after paper conversion."
                    ),
                    SlideCard(
                        title: "Week 1 homework · ~1 hour (due Aug 24)",
                        bullets: [
                            "Paper (30 min): Write, without looking, the difference between '7' and 7. Predict print(10+2) and print('10'+'2'). Then check in Python.",
                            "Type (30 min): From a blank file, the 6-line first program. Run it. Screenshot or copy the output.",
                            "Then add two extra lines: print(100) and print('I finished week 1').",
                            "If an error appears, write the error name (SyntaxError / NameError / TypeError) and which line. Do not delete the whole file.",
                            "Bring: the .py file and one sentence about an error you saw (or ‘no errors’)."
                        ],
                        diagram: "Checklist:\\n[ ] predicted 12 vs 102 before running\\n[ ] 6-line program runs\\n[ ] two extra print lines\\n[ ] error note for class",
                        coachNote: "If she cannot run Python at home, print the 6 lines on paper and ‘trace’ the output column. Still due."
                    ),
                    SlideCard(
                        title: "Week 2 · Aug 24 · meeting (90 min) · bases + int()",
                        bullets: [
                            "0:00–0:15  Homework share: 12 vs 102. Spot-check the 6-line file.",
                            "0:15–0:55  Place value as bundle size. Four bases. Hex A=10…F=15. Convert TO decimal with a power row. Several examples.",
                            "0:55–1:25  Lab: int('7'), int('1A', 16), int('1011', 2), int('77', 8). Check every answer on paper first.",
                            "1:25–1:30  Week 2 homework."
                        ],
                        diagram: "Success tonight:\\n  power row under every numeral\\n  1A16 = 26 on paper AND int('1A',16)\\n  can reject 18 as octal",
                        coachNote: "Keep a hex strip on the table all season."
                    ),
                    SlideCard(
                        title: "You already know place value — we are only changing the bundle size",
                        bullets: [
                            "In everyday math, 347 means 3 hundreds + 4 tens + 7 ones. Each step left is ×10. That is base 10 (decimal).",
                            "Computers also bundle, but they can bundle by 2 (binary), 8 (octal), or 16 (hexadecimal).",
                            "Think of a vending machine that only takes stacks of a certain size. Base 2 = stacks of 2. Base 16 = stacks of 16.",
                            "The digits in a number must be smaller than the base. Base 2 may only use 0 and 1. Base 8 may only use 0–7. Base 16 uses 0–9 and then letters A–F.",
                            "ACSL writes the base as a tiny number after the digits: 1011₂ means ‘this is binary.’ 2F₁₆ means ‘this is hex.’ If there is no tiny number, assume base 10."
                        ],
                        diagram: "Everyday:  3  4  7\nBundles:  100 10  1     (×10 each step left)\n\nBinary:    1  0  1  1\nBundles:   8  4  2  1     (×2 each step left)\nValue: 8+0+2+1 = 11 in everyday numbers",
                        coachNote: "Have students hold up fingers: ‘Show me a legal binary digit.’ Only 0 or 1. Then: ‘Is 18 in octal legal?’ No — 8 is not allowed in base 8."
                    ),
                    SlideCard(
                        title: "The four bases ACSL uses — cheat sheet",
                        bullets: [
                            "Base 2, binary: digits 0,1. Nickname: bits. Looks like 101101₂.",
                            "Base 8, octal: digits 0,1,2,3,4,5,6,7. Looks like 77₈. If you see an 8 or 9, it cannot be octal.",
                            "Base 10, decimal: digits 0–9. This is normal school math. Looks like 47 or 47₁₀.",
                            "Base 16, hexadecimal (hex): digits 0–9 and A=10, B=11, C=12, D=13, E=14, F=15. Looks like 2F₁₆. Letter case does not matter: a = A.",
                            "Memory trick: A is the first letter, so A=10. Then B=11 … F=15. There is no G in hex.",
                            "Say it out loud: ‘2F hex is 2 sixteens and 15 ones.’"
                        ],
                        diagram: "Hex letters (write this in your notes):\nA=10  B=11  C=12  D=13  E=14  F=15\n\nLegal?   18₈  NO (8 is not an octal digit)\nLegal?   1012₂ NO (2 is not a binary digit)\nLegal?   1G₁₆  NO (G is not a hex digit)\nLegal?   1C₁₆  YES (C means 12)",
                        coachNote: "Quiz: point at 2F and ask ‘what is F worth?’ Wait until they say 15, not F."
                    ),
                    SlideCard(
                        title: "How to convert TO everyday numbers (place-value steps)",
                        bullets: [
                            "Step 1: Write the digits in a row.",
                            "Step 2: Under the RIGHTMOST digit write 1. That is the ones place (base⁰ is always 1).",
                            "Step 3: Moving left, multiply the place by the base each time. Base 16: 1, then 16, then 256. Base 2: 1, 2, 4, 8, 16, 32…",
                            "Step 4: Multiply each digit by its place. For hex, change letters to 10–15 first.",
                            "Step 5: Add. That sum is the everyday (decimal) value.",
                            "Worked 1A₁₆: places 16 and 1. Digits 1 and 10. 1×16 + 10×1 = 26."
                        ],
                        diagram: "Example: 1 A  in hex\nPlaces:  16 1\nMath:    1×16 + 10×1 = 16 + 10 = 26\n\nExample: 2 F  in hex\n         2×16 + 15×1 = 32 + 15 = 47\n\nExample: 7 7  in octal\n         7×8 + 7×1 = 56 + 7 = 63\n\nExample: 1 0 1 1 0 1  in binary\nPlaces: 32 16 8 4 2 1\nMath:   32+0+8+4+0+1 = 45",
                        coachNote: "Do 1A on the board with the class calling out each place. Then freeze and have Soha do 2F alone on paper before you write the answer."
                    ),
                    SlideCard(
                        title: "More converted examples — talk through every line",
                        bullets: [
                            "1011₂ → places 8 4 2 1 → 8+0+2+1 = 11₁₀. So 1011₂ is eleven.",
                            "1101₂ → 8+4+0+1 = 13₁₀.",
                            "17₈ → 1×8 + 7 = 15₁₀. Then 15 is F in hex, so 17₈ = F₁₆. Same number, different costume.",
                            "C₁₆ is just 12. One hex digit is a number from 0 to 15.",
                            "10000₂ = 16₁₀ because the 1 sits in the 16s place. Count: 1, 2, 4, 8, 16.",
                            "If ACSL asks ‘convert 1011₂ to hex,’ first go to decimal (11), then 11 is B, so B₁₆. Or use the grouping shortcut (next slides)."
                        ],
                        diagram: "Same value, three costumes:\n  15 in decimal  =  17 in octal  =  F in hex  =  1111 in binary\n\nCheck binary 1111: 8+4+2+1 = 15. Yes.",
                        coachNote: "Physical prop: three sticky notes that all say 15, labeled 15₁₀ / 17₈ / F₁₆. ‘Different outfits, same person.’"
                    ),
                    SlideCard(
                        title: "Python: variables and int() — putting a number in a box",
                        bullets: [
                            "a = 7 means: put 7 in a box named a. Later, a means whatever is in that box.",
                            "a = a - 3 means: take what is in a, subtract 3, put the new value back in a.",
                            "Everything you read with input() is a STRING (text). '16' is not ready for math until int('16').",
                            "int('16') → 16.  int('16') + 1 → 17.  '16' + '1' → '161' (gluing text — usually wrong on ACSL).",
                            "Two equals == asks a yes/no question. One equals = puts something in a box. Never mix them."
                        ],
                        diagram: "n = int('7')      # n is the number 7\nn = n + 1         # n is now 8\nprint(n)          # 8\n\n# Wrong for ACSL math:\ns = '7'\nprint(s + '1')    # prints 71  (text glued together)\n\n# Right:\nprint(int('7') + 1)   # prints 8",
                        coachNote: "Ask: ‘If s is the text 10, what is s + s?’ They should say 1010 as text. Then int(s)+int(s) is 20."
                    ),
                    SlideCard(
                        title: "Python: int(text, base) does the number-system conversion for you",
                        bullets: [
                            "int(text, base) means: read this text as a number in that base, and give me the everyday (decimal) value.",
                            "int('1011', 2) → 11.  int('77', 8) → 63.  int('1A', 16) → 26.  int('2F', 16) → 47.",
                            "The first argument is a STRING. The second is the base as a normal integer: 2, 8, or 16.",
                            "If you forget the quotes, 1A is not legal Python (A looks like a variable name).",
                            "Letters in hex can be upper or lower: int('1a', 16) is also 26.",
                            "This is the same place-value work you did on paper — Python just does the adding."
                        ],
                        diagram: "print(int('1011', 2))   # 11\nprint(int('17', 8))     # 15\nprint(int('1A', 16))    # 26\nprint(int('2F', 16))    # 47\nprint(int('C', 16))     # 12\n\n# Check on paper: 2F = 2×16 + 15 = 47. Matches.",
                        coachNote: "After each print, have them do the paper conversion. Python is the check, not a replacement for understanding."
                    ),
                    SlideCard(
                        title: "Week 2 homework · ~1 hour (due Aug 31)",
                        bullets: [
                            "Paper (30 min): Convert to decimal, drawing the power row: 1011₂, 1101₂, 17₈, 1C₁₆, 2F₁₆. Circle illegal if any.",
                            "Type (30 min): print(int(...)) for each legal one. Write paper answer and Python answer side by side.",
                            "Bonus if time: int('C', 16) and say out loud ‘C is 12’.",
                            "Bring both columns to class. Any mismatch = we redo the power row, not ‘Python is wrong.’"
                        ],
                        diagram: "1011₂ → 11\\n1101₂ → 13\\n17₈ → 15\\n1C₁₆ → 28\\n2F₁₆ → 47",
                        coachNote: "If she only types and skips paper, it does not count as done."
                    ),
                    SlideCard(
                        title: "Week 3 · Aug 31 · meeting (90 min) · remainders, grouping, adding",
                        bullets: [
                            "0:00–0:15  Homework check: five conversions. Fix any reverse remainders early if they show up.",
                            "0:15–0:55  Everyday → binary (divide by 2, read remainders UP). Same for 16 and 8. Grouping 3 and 4, pad LEFT. Adding in binary and hex.",
                            "0:55–1:25  Lab: format(n,'b'), format(n,'o'), format(n,'X'). Compare to paper remainders for 45, 50, 63.",
                            "1:25–1:30  Week 3 homework."
                        ],
                        diagram: "Success tonight:\\n  45 → 101101₂ with arrow UP\\n  101101₂ groups to 55₈ and 2D₁₆\\n  pad zeros on the LEFT",
                        coachNote: "Physical arrow on the remainder list. This is the #1 middle-school bug."
                    ),
                    SlideCard(
                        title: "The other direction: everyday → binary (divide by 2, keep remainders)",
                        bullets: [
                            "Now we start with a normal number, like 45, and want binary.",
                            "Rule: divide by 2. Write the remainder (0 or 1). Repeat with the quotient until you hit 0.",
                            "The FIRST remainder you write is the RIGHTMOST bit (the ones place). So we read the remainder list from bottom to top.",
                            "Circle the last remainder. That is the leftmost 1.",
                            "Always check by converting back with place values. If it does not match, you read the remainders in the wrong order."
                        ],
                        diagram: "45 ÷ 2 = 22  remainder 1   ← ones place (right end)\n22 ÷ 2 = 11  remainder 0\n11 ÷ 2 =  5  remainder 1\n 5 ÷ 2 =  2  remainder 1\n 2 ÷ 2 =  1  remainder 0\n 1 ÷ 2 =  0  remainder 1   ← leftmost bit. STOP.\n\nRead UP the remainders: 1 0 1 1 0 1\nAnswer: 101101₂\nCheck: 32+8+4+1 = 45. Good.",
                        coachNote: "Draw an arrow from the bottom remainder upward. Students who ‘just list remainders downward as the answer’ get the number backwards — the most common middle-school error."
                    ),
                    SlideCard(
                        title: "Everyday → hex and octal (same method, divide by 16 or 8)",
                        bullets: [
                            "Hex: divide by 16. Remainder 10,11,12,13,14,15 become A,B,C,D,E,F.",
                            "Example 26 → hex: 26÷16 = 1 remainder 10. 10 is A. Read up: 1A₁₆.",
                            "Example 50 → hex: 50÷16 = 3 remainder 2. Answer 32₁₆. Check: 3×16+2=50.",
                            "Octal: divide by 8. Example 63÷8 = 7 remainder 7. Answer 77₈.",
                            "Example 45→octal: 45÷8 = 5 remainder 5. Answer 55₈. Check: 5×8+5=45."
                        ],
                        diagram: "50 to hex:\n  50 ÷ 16 = 3  r 2\n   3 ÷ 16 = 0  r 3     ← read up: 32₁₆\n\n26 to hex:\n  26 ÷ 16 = 1  r 10=A\n   1 ÷ 16 = 0  r 1     ← read up: 1A₁₆",
                        coachNote: "When remainder is 10+, they must write a LETTER. Pause and chorus: 10 is A, 11 is B, … 15 is F."
                    ),
                    SlideCard(
                        title: "Python: turning a number INTO binary / hex / octal",
                        bullets: [
                            "Sometimes the problem wants you to print the number in another base as TEXT.",
                            "bin(45) → '0b101101'  (Python adds 0b). You often must strip the prefix.",
                            "hex(26) → '0x1a'.  oct(63) → '0o77'.",
                            "Better for contests: format(45, 'b') → '101101' with no prefix. format(26, 'x') → '1a'. format(63, 'o') → '77'.",
                            "Uppercase hex: format(26, 'X') → '1A'. ACSL may want 1A not 1a — read the problem.",
                            "You can still do it by hand with divide-and-remainders. The computer is a check."
                        ],
                        diagram: "n = 45\nprint(format(n, 'b'))   # 101101     binary\nprint(format(n, 'o'))   # 55         octal\nprint(format(n, 'x'))   # 2d         hex lowercase\nprint(format(n, 'X'))   # 2D         hex uppercase\n\n# If they want no extra 0b:\nprint(bin(n)[2:])       # also 101101  (slice off first two chars)",
                        coachNote: "Show format first. bin()[2:] is a common trick but easier to mess up. format(n,'b') is clearer for middle school."
                    ),
                    SlideCard(
                        title: "Speed trick: grouping bits (why 3 and 4?)",
                        bullets: [
                            "Because 2³ = 8, three binary digits make exactly one octal digit.",
                            "Because 2⁴ = 16, four binary digits make exactly one hex digit.",
                            "Always start grouping from the RIGHT. If you do not have enough bits on the left, pad with 0s on the LEFT. Never pad the right — that would change the number (like adding zeros to 7 to make 70).",
                            "Binary to octal: 101101₂ → 101 | 101 → 5 | 5 → 55₈.",
                            "Binary to hex: 101101₂ → need 8 bits → 0010 | 1101 → 2 | D → 2D₁₆.",
                            "Why D? 1101₂ = 8+4+1 = 13 = D."
                        ],
                        diagram: "Pad LEFT, group RIGHT.\n\n101101  → octal groups of 3:\n  101  101\n   5    5     → 55₈\n\n101101  → hex groups of 4:\n  00 10  1101     (two zeros added on the left)\n     2     D      → 2D₁₆\n\nCheck both equal 45. Same number.",
                        coachNote: "Do one with the class on graph paper boxes. If someone pads on the right, show that 1011 vs 10110 are different numbers."
                    ),
                    SlideCard(
                        title: "Adding like 2nd grade — but the ‘make a new bundle’ number changes",
                        bullets: [
                            "In base 10 you learned: 7+5=12, write 2, carry 1 ten. You carried because you hit 10.",
                            "In base 2 you carry when you hit 2. 1+1 = 2, which is 10 in binary: write 0, carry 1.",
                            "1+1+1 in binary = 3 = 11₂: write 1, carry 1.",
                            "In hex you carry when you hit 16. A+7 means 10+7=17. 17 = 16+1, so write 1, carry 1.",
                            "Always add in everyday numbers in your head, then translate the sum back into that base."
                        ],
                        diagram: "Binary:\n    1 0 1 1     (11)\n  + 0 1 1 0     ( 6)\n  ---------     ---\n  1 0 0 0 1     (17)   because 11+6=17\n\nHex:\n    2 F         F=15, plus 3 = 18\n  + 1 3         18 = 1×16 + 2, so write 2 carry 1\n  -----         2+1+carry1 = 4\n    4 2₁₆",
                        coachNote: "Narrate in English: ‘F is fifteen, plus three is eighteen. Eighteen is one sixteen and two left over.’"
                    ),
                    SlideCard(
                        title: "Week 3 homework · ~1 hour (due Sep 7)",
                        bullets: [
                            "Paper (30 min): 45→binary, 50→hex, 63→octal, 101101₂→octal by grouping, 1011₂+0110₂.",
                            "Type (30 min): format(45,'b'), format(50,'X'), format(63,'o'). Plus int() check that grouping answers match.",
                            "Write ‘pad left’ on the grouping problem so you remember."
                        ],
                        diagram: "45 → 101101₂\\n50 → 32₁₆\\n63 → 77₈\\n101101₂ → 55₈\\n1011+0110 → 10001₂",
                        coachNote: "Collect grouping work. If they padded right, redo that one in the next homework-check."
                    ),
                    SlideCard(
                        title: "Week 4 · Sep 7 · meeting (90 min) · I/O + numbers checkpoint",
                        bullets: [
                            "0:00–0:15  Homework five. Quick grouping recap.",
                            "0:15–0:40  Mixed 5-problem number-systems drill (do now slide). Grade together.",
                            "0:40–0:55  input().strip().split() — tokens, index 0 and 1.",
                            "0:55–1:25  Lab: type the full conversion program. Run 2F 16 → 47, 77 8 → 63, 1011 2 → 11.",
                            "1:25–1:30  Week 4 homework. Checkpoint: we want 8/10 paper next week."
                        ],
                        diagram: "Checkpoint tonight:\\n  drill 5 in class\\n  program prints 47 for 2F 16\\n  no prompt text in input()",
                        coachNote: "If conversion program is not running, skip recursion next week and finish this lab."
                    ),
                    SlideCard(
                        title: "Try these five — number systems (do now, then check)",
                        bullets: [
                            "Put phones away. Paper only. Draw the place row every time.",
                            "1) 1C₁₆ to decimal. (C is 12.)",
                            "2) 110111₂ to octal. Use groups of 3.",
                            "3) 50₁₀ to hex. Divide by 16.",
                            "4) 67₈ to binary. Each octal digit → 3 bits: 6=110, 7=111.",
                            "5) 1010₂ + 1111₂. Add in binary or convert both to decimal, add, convert back."
                        ],
                        diagram: "Answers (reveal after they try):\n1) 1×16 + 12 = 28\n2) 110 111 → 6 7 → 67₈\n3) 50÷16 = 3 r 2 → 32₁₆\n4) 110 111₂\n5) 10+15=25 → 11001₂   (or binary add: 1010+1111=11001)",
                        coachNote: "Do not move to recursion until at least 4/5 are right. Use Interactive Sandbox to check live so it feels like a lab, not a lecture."
                    ),
                    SlideCard(
                        title: "Python: input().strip().split() — how the grader talks to your program",
                        bullets: [
                            "On HackerRank / ACSL programming, a hidden robot types a line, then your program must answer.",
                            "input() reads one line as text, including the Enter at the end.",
                            ".strip() peels off leftover spaces and the Enter. Always strip.",
                            ".split() chops the line on spaces into a LIST (a row of pieces).",
                            "'1A 16'.split() → ['1A', '16']. Piece 0 is the numeral. Piece 1 is the base as text.",
                            "You still must int() the pieces that are supposed to be numbers: int(parts[1]) is 16, not '16'."
                        ],
                        diagram: "Typed by the grader (you never see a person):\n1A 16\n\nline = input().strip()     # '1A 16'\nparts = line.split()       # ['1A', '16']\nnumeral = parts[0]         # '1A'\nbase = int(parts[1])       # 16\nprint(int(numeral, base))  # 26\n\n# NEVER:\n# input('Enter a number:')  ← extra words fail hidden tests",
                        coachNote: "Walk index 0 and 1 with fingers. Middle schoolers mix up which piece is the base. Chant: ‘first token numeral, second token base.’"
                    ),
                    SlideCard(
                        title: "Python: a complete Contest 1 conversion program (type this)",
                        bullets: [
                            "This is a full solution shape: read tokens, convert, print one integer, stop.",
                            "Use sys.stdin.read().split() if there might be extra blank lines. split() with no arguments already splits on all whitespace.",
                            "print() adds a newline. That is what the grader expects. Do not print extra labels.",
                            "If the problem says ‘return an int’ inside a function, you return the number and print it only in main."
                        ],
                        diagram: "import sys\n\ndef solve():\n    parts = sys.stdin.read().strip().split()\n    numeral = parts[0]\n    base = int(parts[1])\n    return int(numeral, base)\n\nif __name__ == '__main__':\n    print(solve())\n\n# Sample: stdin  2F 16   → prints 47\n# Sample: stdin  1011 2  → prints 11\n# Sample: stdin  77 8    → prints 63",
                        coachNote: "Have Soha change only the sample in her head: ‘If I type 77 8, what prints?’ Wait for 63. Then run it."
                    ),
                    SlideCard(
                        title: "Week 4 homework · ~1 hour (due Sep 14)",
                        bullets: [
                            "Paper (30 min): 10 mixed conversions (pick from class list or: 1111₂, 77₈, 10₁₆, 32₁₀→hex, 26₁₀→binary, 55₈→binary grouping, 2D₁₆→decimal, 10000₂, 1A₁₆+1, illegal 19₈).",
                            "Type (30 min): conversion program on three lines of stdin you type yourself: 1A 16, 1011 2, 77 8.",
                            "Bring the 10 paper answers. We start Week 5 only if most are right."
                        ],
                        diagram: "Must-get: 1A 16 → 26,  1011 2 → 11,  77 8 → 63\\nProgram prints ONLY the number.",
                        coachNote: "This is the gate to recursion. Do not open Week 5 slides if numbers are still mushy."
                    ),
                    SlideCard(
                        title: "Week 5 · Sep 14 · meeting (90 min) · recursion tables + def f",
                        bullets: [
                            "0:00–0:15  Week 4 paper spot-check.",
                            "0:15–0:55  Recursion in English. Table method. f(0)=1, f(n)=n+f(n-1) up to f(4)=11. Ban the word factorial.",
                            "0:55–1:25  Lab: def f(n) with return. print(f(0))…print(f(4)). Then print vs return slide — show the broken print-inside version if time.",
                            "1:25–1:30  Week 5 homework."
                        ],
                        diagram: "Success tonight:\\n  table with n | f(n) | how\\n  f(4) boxed 11\\n  code print(f(4)) is 11",
                        coachNote: "If they multiply, stop and rebuild the add table from f(0)."
                    ),
                    SlideCard(
                        title: "Recursion in plain English",
                        bullets: [
                            "Recursion = a rule that uses a smaller version of itself, plus a STOP rule.",
                            "The stop rule is the BASE CASE. Example: ‘If I have 0 boxes, the answer is 1. Stop.’",
                            "The keep-going rule is the RECURSIVE CASE. Example: ‘If I have n boxes, the answer is n plus the answer for n−1 boxes.’",
                            "Real-life picture: a stack of plates. To count plates, it is 1 + (the count of the plates under this one). The floor is 0 plates.",
                            "You do NOT need to ‘understand infinity.’ You only compute a table from the bottom up.",
                            "ACSL writes: f(0)=1  and  f(n)=n+f(n−1) when n>0. That is the plate-counting rule."
                        ],
                        diagram: "Plates:\nf(0) = 1          ← empty extra ‘ghost’ plate ACSL gave us as the stop\nf(1) = 1 + f(0) = 2\nf(2) = 2 + f(1) = 4\nf(3) = 3 + f(2) = 7\nf(4) = 4 + f(3) = 11\n\nThis is NOT factorial. Factorial would multiply. We added.",
                        coachNote: "Ban the word factorial until they finish the table. Middle schoolers who just finished n! will try to multiply and miss the point."
                    ),
                    SlideCard(
                        title: "Contest method: fill a table (this is how you score the point)",
                        bullets: [
                            "Draw two columns: n and f(n).",
                            "Write the base case in row n=0 (or whatever they gave you).",
                            "Each next row uses ONLY the row above. No trees required on the contest.",
                            "Box the row they asked for. That number is the answer. Do not keep going ‘for fun’ and copy the wrong row.",
                            "Off-by-one trap: f(4) is the row where n=4, not the 4th number you scribbled if you started at f(1)."
                        ],
                        diagram: " f(0)=1,  f(n)=n+f(n-1)\n\n n | f(n) | how I got it\n 0 |  1   | given\n 1 |  2   | 1 + 1\n 2 |  4   | 2 + 2\n 3 |  7   | 3 + 4\n 4 | 11   | 4 + 7     ← if they ask f(4), box 11",
                        coachNote: "Have Soha copy this exact table format on every recursion question for the rest of the season."
                    ),
                    SlideCard(
                        title: "Python: recursion is just the table, written as a function",
                        bullets: [
                            "def f(n): starts a function named f that needs one number n.",
                            "The base case is an if that RETURNS and does not call f again.",
                            "The recursive case RETURNS an expression that includes f(something smaller).",
                            "return hands a value back. It is not the same as print. Recursion needs return so the next level can use the number.",
                            "If you forget the base case, Python explodes with RecursionError (too many calls)."
                        ],
                        diagram: "def f(n):\n    if n == 0:          # BASE CASE — stop\n        return 1\n    return n + f(n - 1) # RECURSIVE CASE — smaller n\n\nprint(f(0))   # 1\nprint(f(1))   # 2\nprint(f(4))   # 11   same table as on paper\n\n# Paper table: 0→1, 1→2, 2→4, 3→7, 4→11",
                        coachNote: "Project this next to the paper table. Point at return 1 and the f(0) row. Then f(4) and 11. Same object, two outfits."
                    ),
                    SlideCard(
                        title: "Python: print vs return (middle school mix-up #1)",
                        bullets: [
                            "print shows a value on the screen. The grader reads the screen.",
                            "return sends a value back to whoever called the function. The caller can store it or print it.",
                            "In recursion you almost always return. If you only print inside f, the next f(n-1) has nothing to add.",
                            "Contest main program: compute with return, then one print of the final answer.",
                            "Printing inside a recursive function can spam extra lines and fail hidden tests."
                        ],
                        diagram: "def f(n):\n    if n == 0:\n        return 1     # NOT print(1)\n    return n + f(n - 1)\n\nprint(f(4))          # ONE line: 11\n\n# Broken:\ndef broken(n):\n    if n == 0:\n        print(1)     # shows 1, but returns None\n        return\n    return n + broken(n - 1)  # crash: None + int",
                        coachNote: "Say: ‘return is for math between function calls. print is the postcard you mail to the grader, once.’"
                    ),
                    SlideCard(
                        title: "Week 5 homework · ~1 hour (due Sep 21)",
                        bullets: [
                            "Paper (30 min): table f(0) through f(6) for f(0)=1, f(n)=n+f(n-1). Box f(5) and f(6).",
                            "Type (30 min): the function. print(f(4)), print(f(5)), print(f(6)). Must match the table (11, 16, 22).",
                            "Write one sentence: why return is required inside f, not print."
                        ],
                        diagram: "f(0)=1\\nf(1)=2\\nf(2)=4\\nf(3)=7\\nf(4)=11\\nf(5)=16\\nf(6)=22",
                        coachNote: "Mismatch means they printed inside f or skipped a row."
                    ),
                    SlideCard(
                        title: "Week 6 · Sep 21 · meeting (90 min) · harder recursion",
                        bullets: [
                            "0:00–0:15  Check f(6)=22.",
                            "0:15–0:55  Second rule n*f(n-1)+1. Even/odd. Two-argument GRID. Drill A/B/C. Highlight A: f(4)=33 not 17.",
                            "0:55–1:25  Lab: second def f. range(0,5) prints k=0..4. Code drill A.",
                            "1:25–1:30  Week 6 homework."
                        ],
                        diagram: "Trap of the week: stopping at f(3)=17.\\nCorrect A: 3,5,9,17,33.",
                        coachNote: "Fill the 3x3 grid on the projector with the class. No mental recursion."
                    ),
                    SlideCard(
                        title: "A second recursion — multiply and add",
                        bullets: [
                            "New rule: f(0)=2, and f(n)= n × f(n−1) + 1.",
                            "Still a table. Do not try to ‘see the pattern’ until three rows are filled.",
                            "f(1)= 1×2 + 1 = 3",
                            "f(2)= 2×3 + 1 = 7",
                            "f(3)= 3×7 + 1 = 22",
                            "f(4)= 4×22 + 1 = 89",
                            "If they ask f(3), the answer is 22, not 89."
                        ],
                        diagram: " n | f(n)\n 0 |  2\n 1 |  3     1*2+1\n 2 |  7     2*3+1\n 3 | 22     3*7+1\n 4 | 89     4*22+1",
                        coachNote: "Ask: ‘What is the base case?’ Wait for ‘f(0)=2’. Then ‘what do I do each step?’ Wait for ‘multiply by n, then add 1.’"
                    ),
                    SlideCard(
                        title: "Python: another recursive function (the multiply-and-add one)",
                        bullets: [
                            "Paper rule: f(0)=2, f(n)= n * f(n-1) + 1.",
                            "Python: if n==0: return 2.  else: return n * f(n-1) + 1.",
                            "Print a loop of values so students see the table appear on screen.",
                            "for k in range(0, 5): means k = 0,1,2,3,4. range stops BEFORE the second number."
                        ],
                        diagram: "def f(n):\n    if n == 0:\n        return 2\n    return n * f(n - 1) + 1\n\nfor k in range(0, 5):\n    print(k, f(k))\n\n# prints:\n# 0 2\n# 1 3\n# 2 7\n# 3 22\n# 4 89",
                        coachNote: "range(0,5) trap: it does not include 5. If they want f(0) through f(5) they need range(0,6)."
                    ),
                    SlideCard(
                        title: "Even/odd recursion and two-number recursion",
                        bullets: [
                            "Sometimes the rule changes if n is even or odd. Check even/odd EACH row. Even means n is divisible by 2.",
                            "Example: f(0)=0. If n is even, f(n)=f(n−1)+n. If n is odd, f(n)=f(n−1)−1.",
                            "Two-number recursion looks scary: f(x,y)=f(x−1,y)+f(x,y−1), and anything with a 0 is 1.",
                            "Fix: draw a GRID. First fill the 0-row and 0-column with 1s. Then each inner square is LEFT plus ABOVE.",
                            "f(1,1)=f(0,1)+f(1,0)=1+1=2.  f(2,2) becomes 6 if you fill carefully. Do not skip squares."
                        ],
                        diagram: "Grid (x down, y across). Edges are 1:\n       y=0  y=1  y=2\n x=0    1    1    1\n x=1    1    2    3     ← 1+1=2, then 2+1=3\n x=2    1    3    6     ← 1+2=3, then 3+3=6",
                        coachNote: "Project the empty grid. Fill it with the class like a tiny KenKen. Never let them recurse two arguments in their head."
                    ),
                    SlideCard(
                        title: "Try these three — recursion (do now)",
                        bullets: [
                            "A) f(0)=3, f(n)=2×f(n−1)−1. Find f(4). Write every row 0 through 4.",
                            "B) g(0)=0, g(1)=1, g(n)=g(n−1)+g(n−2)+1. Find g(5). You need TWO previous rows, like a Fibonacci cousin.",
                            "C) h(0)=0, h(n)=n−h(n−1). Find h(6).",
                            "Trap on A: people stop at 17, which is f(3). Keep going to n=4."
                        ],
                        diagram: "A rows: f(0)=3\n        f(1)=2*3-1=5\n        f(2)=2*5-1=9\n        f(3)=2*9-1=17\n        f(4)=2*17-1=33     ← 33 not 17\n\nB: 0, 1, 2, 4, 7, 12      g(5)=12\n   (0+1+1=2, 1+2+1=4, 2+4+1=7, 4+7+1=12)\n\nC: 0, 1, 1, 2, 2, 3, 3    h(6)=3",
                        coachNote: "Celebrate the 17-vs-33 trap out loud so they remember it on contest day."
                    ),
                    SlideCard(
                        title: "Week 6 homework · ~1 hour (due Sep 28)",
                        bullets: [
                            "Paper (30 min): A, B, C from the drill slide with every row written. A must show 33.",
                            "Type (30 min): function for A. print(f(4)) → 33. Optional: loop print k, f(k) for k in range(0,5).",
                            "Draw one 3×3 two-arg grid (edges 1) if you still have time."
                        ],
                        diagram: "A f(4)=33\\nB g(5)=12\\nC h(6)=3",
                        coachNote: "If A is 17, they did not count f(0) as a row. Redo A only, fully."
                    ),
                    SlideCard(
                        title: "Week 7 · Sep 28 · meeting (90 min) · if/else",
                        bullets: [
                            "0:00–0:15  Recursion homework. Celebrate 33.",
                            "0:15–0:55  Hallway if. elif vs two separate ifs. Nested if. Paper P1–P3. Cover else with a sheet of paper.",
                            "0:55–1:25  Lab: type those programs. Then change n=12 on the two-if program and predict before run.",
                            "1:25–1:30  Week 7 homework."
                        ],
                        diagram: "P1 → 4 5\\nP2 → 2  (two ifs)\\nP3 → 10\\nTwo IFs can both run.",
                        coachNote: "If P2 comes back 7, they invented an else. Circle the missing else."
                    ),
                    SlideCard(
                        title: "If/else is a fork in the hallway — you take ONE path",
                        bullets: [
                            "A program is a list of instructions. The computer is extremely literal. It does not ‘know what you meant.’",
                            "if CONDITION: do the indented lines. else: do the other indented lines. Only one of those two blocks runs.",
                            "Indentation (the spaces at the start of the line) shows which lines belong to the if.",
                            "The test uses == (two equals) to ASK ‘are these the same?’ A single = SETS a variable. Mixing them is a wrong answer.",
                            "Make a table with columns for each variable. Update the table after EVERY line that runs. Skip lines that did not run. Draw a slash through skipped lines.",
                            "The contest asks what gets printed, or the final values. Read the last line: print(a, b) means both numbers, in that order."
                        ],
                        diagram: "a, b = 7, 3     # start: a=7, b=3\nif a > b:        # 7>3 is True, so do the next indented line\n    a = a - b    # a becomes 4.  b stays 3\nelse:\n    b = b - a    # SKIPPED because if was True\nprint(a, b)      # prints: 4 3",
                        coachNote: "Cover the else with a sheet of paper when the if is true. Physical covering stops ‘I also did the else just in case.’"
                    ),
                    SlideCard(
                        title: "elif means ‘else if’ — still only ONE winner",
                        bullets: [
                            "if / elif / else is a chain. The computer checks from the top. The FIRST true condition wins. The rest are ignored.",
                            "Two separate ifs (no else) are different: BOTH can run. ACSL loves this trap.",
                            "and means both parts must be true. or means at least one part is true.",
                            "% is remainder: 5 % 2 is 1 (odd). 6 % 2 is 0 (even). ‘If n%2==0’ means ‘if n is even.’",
                            "// is whole-number divide: 5//2 is 2, not 2.5."
                        ],
                        diagram: "TWO IFs (both can run):\nn = 7\nif n > 10:\n    n = n - 10     # skipped, 7 is not > 10\nif n > 5:\n    n = n - 5      # runs, n becomes 2\nprint(n)           # 2\n\nIf this had been if/else, the second test would never happen.",
                        coachNote: "Write ‘ELSE = exclusive’ and ‘TWO IFS = both possible’ as a poster line."
                    ),
                    SlideCard(
                        title: "Walk a nested if together (slow)",
                        bullets: [
                            "Nested means an if inside an if. Like a hallway with a second door inside the first room.",
                            "You only look at the inner door if you already entered the outer room.",
                            "Program: if a>5: then if a>10: a=0 else: a=a-1. The inner else belongs to a>10, not to a>5.",
                            "Try a=8: outer true (8>5). Inner 8>10 is false, so a=8-1=7. Print 7.",
                            "Try a=12: outer true. Inner true, so a=0.",
                            "Try a=3: outer false. Inner never runs. a stays 3."
                        ],
                        diagram: "a = 8\nif a > 5:           # True, go inside\n    if a > 10:      # False\n        a = 0       # skip\n    else:\n        a = a - 1   # a = 7\nprint(a)            # 7\n\nCollatz-style:\na = 5\nif a % 2 == 0:      # 5 is odd, False\n    a = a // 2\nelse:\n    a = 3 * a + 1   # 16\nprint(a)            # 16",
                        coachNote: "Three volunteers: a=8, a=12, a=3. Each walks the doors. Class votes before you reveal."
                    ),
                    SlideCard(
                        title: "Python: if / elif / else — same forks as the tracing problems",
                        bullets: [
                            "Colon : at the end of if/else. Next lines must be indented (4 spaces is the contest habit).",
                            "elif means else if. Still only one block runs in a chain.",
                            "Two separate ifs (no else) can both run — same trap as on paper.",
                            "and / or work in Python the same way: both true / at least one true.",
                            "After tracing on paper, TYPE the program and print. If paper and Python disagree, the paper table missed a line."
                        ],
                        diagram: "a, b = 7, 3\nif a > b:\n    a = a - b\nelse:\n    b = b - a\nprint(a, b)    # 4 3\n\nn = 7\nif n > 10:\n    n = n - 10\nif n > 5:      # second IF, not else\n    n = n - 5\nprint(n)       # 2",
                        coachNote: "Type the two-if program live. Change n to 12 and predict before running: first if fires (n=2), second if does not (2>5 false). Print 2."
                    ),
                    SlideCard(
                        title: "Try these three — if/else (do now)",
                        bullets: [
                            "P1: a,b = 4,9. if a>b: a=a+1  elif a==b: a=0  else: b=b-a. Print a and b.",
                            "P2: n=7. if n>10: n=n-10.   Then a NEW if n>5: n=n-5. Print n. (two ifs)",
                            "P3: x=2, y=5. if x<y and y<10: x=x*y. Print x.",
                            "Write True/False next to each test before you change any variable."
                        ],
                        diagram: "P1: 4>9 False. 4==9 False. else: b=9-4=5. Print 4 5\nP2: 7>10 False. 7>5 True, n=2. Print 2\nP3: 2<5 True AND 5<10 True, so x=10. Print 10",
                        coachNote: "If P2 comes back as 7, they treated it as else. Circle the missing else."
                    ),
                    SlideCard(
                        title: "Week 7 homework · ~1 hour (due Oct 5)",
                        bullets: [
                            "Paper (30 min): retrace P1–P3 plus one nested if with a=8 and a=3. True/False beside every test.",
                            "Type (30 min): P2 program. Run n=7 (expect 2) and n=12 (first if → 2, second if skipped, print 2).",
                            "Write: ‘== asks; = puts in a box.’"
                        ],
                        diagram: "n=7  two-if → 2\\nn=12 two-if → 2\\n(12>10 so n=2; 2>5 is false)",
                        coachNote: "Have them bring the True/False marks. That is the skill, not the final number."
                    ),
                    SlideCard(
                        title: "Week 8 · Oct 5 · meeting (90 min) · mock + contest checklist",
                        bullets: [
                            "0:00–0:15  If/else homework.",
                            "0:15–0:40  Hidden-test mistakes. Three mini programs A/B/C (convert, f(4), if/elif).",
                            "0:40–1:10  Team Mock Exams → Contest 1 (5 short-answer). Quiet. Then reveal keys and walk misses.",
                            "1:10–1:25  Contest-day checklist. One combined .py: convert or recurse as assigned, print only the answer.",
                            "1:25–1:30  Light homework: sleep and a short mixed review, no new topics."
                        ],
                        diagram: "Target: mock ≥ 4/5\\nProgramming output is EXACTLY the number\\nHex strip A=10…F=15 in the pencil case",
                        coachNote: "Do not teach Contest 2 tonight. Confidence > new content."
                    ),
                    SlideCard(
                        title: "Python mistakes that fail ACSL hidden tests",
                        bullets: [
                            "input('Enter:') — extra prompt text. Use bare input() or sys.stdin.",
                            "Forgetting int() — you add strings and get '161' instead of 17.",
                            "Printing a list: print(parts) shows ['1A','16'] with brackets. The grader wanted 26.",
                            "Wrong return type: returning a string '26' when they compare as integers can still work with print, but do not return a list.",
                            "Off-by-one in range: range(1,4) is 1,2,3 only.",
                            "Using = inside if (if a = 7) is a syntax error. Use ==."
                        ],
                        diagram: "# Hidden test compares EXACT output.\n# Wanted:   26\\n\nprint(26)                 # pass\nprint('26')               # often still pass (same text)\nprint('The answer is 26') # FAIL\nprint([26])               # FAIL  [26]\nprint(26, 16)             # FAIL  26 16",
                        coachNote: "Show one failing print on purpose so they see how picky the robot is."
                    ),
                    SlideCard(
                        title: "Python do-now — three mini programs (type and run)",
                        bullets: [
                            "A) Read '1011 2' and print the decimal value. (11)",
                            "B) Define f with f(0)=1, f(n)=n+f(n-1). Print f(4). (11)",
                            "C) a,b=4,9 with the if/elif/else from the paper drill. Print a and b. (4 5)",
                            "If any output is wrong, trace on paper first, then fix one line of code. Do not rewrite the whole file."
                        ],
                        diagram: "# A\nparts = input().strip().split()\nprint(int(parts[0], int(parts[1])))\n\n# B\ndef f(n):\n    if n == 0:\n        return 1\n    return n + f(n - 1)\nprint(f(4))\n\n# C\na, b = 4, 9\nif a > b:\n    a = a + 1\nelif a == b:\n    a = 0\nelse:\n    b = b - a\nprint(a, b)",
                        coachNote: "This is the exit ticket. Soha should have all three outputs before leaving. Then copy homework from the Python tab."
                    ),
                    SlideCard(
                        title: "Python on the contest computer (put it all together)",
                        bullets: [
                            "The grader types stdin. You never chat with a human.",
                            "Parse: parts = input().strip().split()  or  sys.stdin.read().strip().split()",
                            "Convert bases with int(numeral, base). Recursion with return + a base case.",
                            "Print only the required value. No extra words, no debug traces.",
                            "Next: open the Python HackerRank Simulator tab and use Copy homework."
                        ],
                        diagram: "stdin:  1A 16\n\nparts = input().strip().split()   # ['1A', '16']\nprint(int(parts[0], int(parts[1])))\n# 26\n\n# Recursion sample stdin: 4\n# print(f(int(input().strip())))  → 11",
                        coachNote: "End class on this slide, then Sandbox 2F₁₆, then Python tab. Celebrate 47 and 11."
                    ),
                    SlideCard(
                        title: "Week 8 homework · ~1 hour (due before contest) · light review only",
                        bullets: [
                            "Paper (30 min): one conversion, one recursion table f(4), one if-trace. That’s it.",
                            "Type (30 min): rerun conversion on 2F 16 and print(f(4)). Confirm 47 and 11.",
                            "Pack: pencils, hex strip, reminder card: power row, remainders UP, cover else, strip().split(), one print.",
                            "Sleep. No new functions, no YouTube rabbit holes."
                        ],
                        diagram: "Contest card:\\n1. Power row\\n2. Remainders read UP\\n3. Cover the else\\n4. parts = input().strip().split()\\n5. print(only the answer)",
                        coachNote: "Send a one-line check-in: 47 and 11 still work."
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
