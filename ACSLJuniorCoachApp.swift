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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Text("Junior (grade 9 and under): 30-minute paper of 6 questions (2 per topic, 5 pts) plus one 72-hour HackerRank program (5 pts). Season max 40. Finals bar 24.")
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
                weekRow("3", "Aug 31", "Remainders, grouping, add/sub/mul, fractions")
                weekRow("4", "Sep 7", "split(); conversion program; numbers checkpoint")
                weekRow("5", "Sep 14", "Recursion tables; def f(n); return vs print")
                weekRow("6", "Sep 21", "Harder recursion: negatives, two-arg, pictures")
                weekRow("7", "Sep 28", "If/elif/else on paper and in Python")
                weekRow("8", "Oct 5", "Mock 6 short-answer + 72-hour programming checklist")
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
            MetricTile(title: "Short-Answer", value: "6 Qs / 5 pts", detail: "2 per topic")
            MetricTile(title: "Programming", value: "5 pts", detail: "72-hour HR")
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
                            "You will also write one Python program on HackerRank. You get about 72 hours after the short-answer. Hidden tests grade exact print output.",
                            "Junior Division: no student beyond grade 9. Short-answer is 30 minutes online. We meet once a week for 1.5 hours, plus about 1 hour of homework.",
                            "Goal today: convert a number on paper AND in Python, fill a recursion table AND write def f(n), trace an if-program AND run it."
                        ],
                        diagram: "Paper: 6 questions, 2 per topic, 30 minutes, 5 pts\nProgram: 1 HackerRank problem, ~72 hours, 5 pts\nJunior: grade 9 and under\nTogether: 10 pts this contest",
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
                            "0:15–0:40  Meet each base as its own world: binary lights, octal 0–7, hex A–F. Do nows. No long recipe yet.",
                            "0:40–0:55  Only then: power-row convert TO decimal. 1A and 2F.",
                            "0:55–1:25  Lab: int('7'), int('1A', 16), int('1011', 2), int('77', 8). Check every answer on paper first.",
                            "1:25–1:30  Week 2 homework."
                        ],
                        diagram: "Success tonight:\\n  count 0–16 in binary\\n  10₈ is 8, 10₁₆ is 16, F is 15\\n  then 1A₁₆ = 26 on paper AND int('1A',16)",
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
                        title: "Why computers even have other number systems",
                        bullets: [
                            "A computer wire is either ON or OFF. That is one bit: 1 or 0. There is no ‘maybe 7’ on a single wire.",
                            "So the machine’s native language is binary (base 2). Long strings of 0s and 1s are ugly for humans: 10000001111000101100 is one number.",
                            "Octal (base 8) and hex (base 16) are shorthand for those bits. One octal digit stands for 3 bits. One hex digit stands for 4 bits. We will use that later — tonight just know WHY they exist.",
                            "Decimal (base 10) is still how we talk to each other. ACSL will bounce among all four costumes of the SAME number.",
                            "We will meet each base as its own world before we convert anything. Do not skip ahead to the recipe."
                        ],
                        diagram: "One wire:   OFF=0   ON=1     (a bit)\nThree wires: 000,001,010,011,100,101,110,111\n             eight patterns = one octal digit 0–7\nFour wires:  16 patterns = one hex digit 0–F",
                        coachNote: "Lights or fingers: three students hold 0/1. Count 0 to 7 out loud. That IS octal, they just do not know the name yet."
                    ),
                    SlideCard(
                        title: "Decimal (base 10) — the one you already speak",
                        bullets: [
                            "Ten digit symbols: 0 1 2 3 4 5 6 7 8 9. After 9 you make a new bundle of ten and write 10.",
                            "Places from the right: ones, tens, hundreds, thousands… Each step left is ×10.",
                            "347 = 3×100 + 4×10 + 7×1. You have done this since 2nd grade.",
                            "ACSL still writes 347₁₀ when they want to shout ‘this one is everyday.’ If there is no subscript, assume decimal.",
                            "Every other base copies THIS idea. Only the bundle size and the allowed digits change."
                        ],
                        diagram: "  3    4    7\n 100   10    1     places (powers of 10)\n 300 + 40 +  7  = 347\n\nPowers of 10: 1, 10, 100, 1000, 10000…",
                        coachNote: "Write 347 with boxes. We will draw the same boxes for binary next, just with 8 4 2 1."
                    ),
                    SlideCard(
                        title: "Binary (base 2) — only 0 and 1, the computer’s alphabet",
                        bullets: [
                            "Two digit symbols only: 0 and 1. Nickname: bits (binary digits). 2 is ILLEGAL in binary. 1012₂ is not a number — it has a 2.",
                            "After you run out of symbols you bundle: 1, then 10 (that is two), then 11 (three), then 100 (four). It looks like you skipped, but you did not. You just have no digit 2.",
                            "Places from the right: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024… Each step left is ×2. Memorize at least through 256 this week.",
                            "A 1 means ‘use this place.’ A 0 means ‘skip this place.’ 1011₂ = 8+0+2+1 = eleven.",
                            "Reading aloud: say ‘one zero one one, base two,’ not ‘one thousand eleven.’ It is not a decimal look-alike."
                        ],
                        diagram: "Count in binary (stay here until this feels boring):\n0=0    1=1    2=10   3=11\n4=100  5=101  6=110  7=111\n8=1000 9=1001 10=1010 11=1011\n12=1100 13=1101 14=1110 15=1111  16=10000\n\nPlaces:  … 16  8  4  2  1",
                        coachNote: "Chorus count 0–16 in binary. If they rush, stop at 8=1000 and rebuild 4,2,1 with fingers."
                    ),
                    SlideCard(
                        title: "Binary — live with 8 4 2 1 before any converting recipe",
                        bullets: [
                            "Draw four boxes labeled 8, 4, 2, 1. Drop a 1 or 0 in each box. That is a 4-bit number.",
                            "1000₂ is 8. 0100₂ is 4. 0010₂ is 2. 0001₂ is 1. Those four ‘pure’ numbers are the whole system.",
                            "Mix them: 1101₂ = 8+4+0+1 = 13. 0110₂ = 4+2 = 6. 1111₂ = 8+4+2+1 = 15 (all lights on).",
                            "Five bits adds a 16s box on the left: 10000₂ = 16. 10110₂ = 16+4+2 = 22.",
                            "We are still not ‘converting’ as a recipe. We are reading a panel of lights."
                        ],
                        diagram: "  8  4  2  1     lights\n  1  0  1  1     on off on on\n  8 +0 +2 +1  = 11\n\n  1  1  0  1  = 8+4+1 = 13\n  0  1  1  1  = 4+2+1 = 7\n  1  0  0  0  = 8",
                        coachNote: "Physical: four index cards 8/4/2/1. Flip face-up for 1. Build 13, then 7, then 16 with a fifth card."
                    ),
                    SlideCard(
                        title: "Do now · binary only (2 min)",
                        bullets: [
                            "No octal, no hex yet. Lights only.",
                            "Q1. What everyday number is 1100₂?",
                            "Q2. What everyday number is 10000₂?",
                            "Q3. Is 102₂ a legal binary numeral? Why?"
                        ],
                        diagram: "Q1  8+4=12\\nQ2  16\\nQ3  NO — digit 2 is not allowed in base 2",
                        coachNote: "If Q1 comes back 1100, they read it as decimal. Say the places out loud with them."
                    ),
                    SlideCard(
                        title: "Octal (base 8) — digits 0 through 7, bundles of eight",
                        bullets: [
                            "Eight digit symbols: 0 1 2 3 4 5 6 7. There is no 8 and no 9 in octal. 18₈ is illegal. 17₈ is fine.",
                            "You bundle when you hit eight, not ten. After 7₈ comes 10₈, which is eight in everyday numbers — not ten.",
                            "Places from the right: 1, 8, 64, 512, 4096. Each step left is ×8. (1, then 8, then 64…)",
                            "Why octal exists: 8 is 2×2×2, so one octal digit is exactly three bits. 7₈ = 111₂. 5₈ = 101₂. We use that as a speed trick later.",
                            "Read 77₈ as ‘seven seven, base eight,’ then think 7 eights and 7 ones = 56+7=63 everyday — but that thought comes AFTER you know the digits."
                        ],
                        diagram: "Octal count (everyday value in parentheses):\n0 1 2 3 4 5 6 7   then 10₈ (=8)  11₈ (=9)  12₈ (=10)\n… 17₈ (=15)  20₈ (=16)\n\nPlaces:  … 512  64  8  1\n\nLegal?  8₈  NO     70₈  YES     19₈  NO",
                        coachNote: "Quiz ‘what comes after 7 in octal?’ They must say 10, not 8. Write 10₈ = 8₁₀ on the board and leave it."
                    ),
                    SlideCard(
                        title: "Octal — sit with a two-digit number before converting lists",
                        bullets: [
                            "A two-digit octal number  ab₈  means a eights and b ones. a and b are each 0–7.",
                            "10₈ = 1×8 + 0 = 8.  20₈ = 16.  30₈ = 24. The left digit is ‘how many eights.’",
                            "17₈ = 1×8 + 7 = 15.  77₈ = 7×8 + 7 = 63.  12₈ = 8+2 = 10.",
                            "Three digits add a 64s place: 100₈ = 64.  101₈ = 65.  777₈ = 7×64 + 7×8 + 7 = 511.",
                            "Still no long recipe. If you can say ‘this is 3 eights and 2 ones,’ you understand octal."
                        ],
                        diagram: "  7  7₈\n  8  1     places\n 56 +7  = 63₁₀\n\n  1  0  1₈\n 64  8  1\n 64 +0 +1 = 65₁₀\n\nEach octal digit 0–7 as 3 bits (preview):\n0=000 1=001 2=010 3=011\n4=100 5=101 6=110 7=111",
                        coachNote: "Have Soha invent a legal 2-digit octal and say it in English before anyone multiplies."
                    ),
                    SlideCard(
                        title: "Do now · octal only (2 min)",
                        bullets: [
                            "Q1. What everyday number is 10₈? (Trap: it looks like ten.)",
                            "Q2. What everyday number is 25₈?",
                            "Q3. Circle the illegal one: 16₈    18₈    70₈"
                        ],
                        diagram: "Q1  8   (one eight, zero ones)\\nQ2  2×8+5=21\\nQ3  18₈ is illegal (digit 8)",
                        coachNote: "Celebrate if they say 8 for Q1. That is the whole lesson."
                    ),
                    SlideCard(
                        title: "Hexadecimal (base 16) — we ran out of digits, so we use letters",
                        bullets: [
                            "Sixteen symbols. 0–9 are the same. Then A=10, B=11, C=12, D=13, E=14, F=15. There is no G.",
                            "Why letters: we need single characters for ten through fifteen. A is the first letter, so A is ten. F is the sixth letter after 9, so F is fifteen.",
                            "You bundle when you hit sixteen. After F₁₆ comes 10₁₆, which is sixteen in everyday numbers — not ten.",
                            "Places from the right: 1, 16, 256, 4096, 65536. Each step left is ×16.",
                            "Lowercase a–f means the same as A–F. ACSL usually prints uppercase. You may write either unless the sample uses one style."
                        ],
                        diagram: "Hex digits (write this strip and keep it all season):\n0 1 2 3 4 5 6 7 8 9  A  B  C  D  E  F\n0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15\n\nAfter F comes 10₁₆ (=16₁₀)\n11₁₆ = 17₁₀    1F₁₆ = 31₁₀    20₁₆ = 32₁₀",
                        coachNote: "Point at F until they say fifteen. Point at 10 hex until they say sixteen. Do not move on until both are automatic."
                    ),
                    SlideCard(
                        title: "Hex — two-digit numbers and ‘what is F worth?’",
                        bullets: [
                            "A two-digit hex number  xy₁₆  means x sixteens and y ones. Change letters to 10–15 BEFORE multiplying.",
                            "10₁₆ = 16.  20₁₆ = 32.  A0₁₆ = 10×16 = 160.  The left digit is ‘how many sixteens.’",
                            "1A₁₆ = 1×16 + 10 = 26.  2F₁₆ = 2×16 + 15 = 47.  FF₁₆ = 15×16 + 15 = 255.",
                            "One hex digit is a number 0–15. C₁₆ is just 12. That is why hex is a nice costume for four bits: 15 = 1111₂ = F₁₆.",
                            "Say every hex numeral in English once: ‘2F is two sixteens and fifteen ones.’ Then, and only then, multiply."
                        ],
                        diagram: "  2  F₁₆\n 16  1\n 32 +15 = 47₁₀\n\n  1  A₁₆\n 16  1\n 16 +10 = 26₁₀\n\n  F  F₁₆\n 16  1\n240 +15 = 255₁₀\n\nEach hex digit as 4 bits (preview):\n9=1001  A=1010  B=1011\nC=1100  D=1101  E=1110  F=1111",
                        coachNote: "Freeze on F=15. If they multiply 2×16+F as ‘2×16+F’ they are not ready for the conversion recipe."
                    ),
                    SlideCard(
                        title: "Do now · hex only (2 min)",
                        bullets: [
                            "Hex strip on the desk. No rushing to Python.",
                            "Q1. What is F worth in everyday numbers?",
                            "Q2. What everyday number is 10₁₆?",
                            "Q3. What everyday number is 1C₁₆? (C is 12.)",
                            "Q4. Illegal or legal: 1G₁₆"
                        ],
                        diagram: "Q1  15\\nQ2  16   (not ten)\\nQ3  16+12=28\\nQ4  illegal — no G",
                        coachNote: "Q2 is the octal trap in a new costume. Same joke: 10 in base b is b itself."
                    ),
                    SlideCard(
                        title: "The four costumes of one number — look, do not convert yet",
                        bullets: [
                            "Pick the everyday number 15. Binary costume 1111₂ (four lights on: 8+4+2+1). Octal costume 17₈ (one eight and seven). Hex costume F₁₆ (one digit, fifteen).",
                            "Pick 16. Binary 10000₂. Octal 20₈. Hex 10₁₆. Decimal 16. Four outfits, one person.",
                            "Pick 10 decimal. Binary 1010₂. Octal 12₈. Hex A₁₆. Notice 10₈ is NOT this number — 10₈ is eight.",
                            "Rule you can chant: ‘10 in base b means b.’ 10₂=2, 10₈=8, 10₁₀=10, 10₁₆=16.",
                            "NOW we are ready for a conversion recipe. Until this slide, the job was to know each world."
                        ],
                        diagram: "15 = 1111₂ = 17₈ = F₁₆\n16 = 10000₂ = 20₈ = 10₁₆\n10 = 1010₂ = 12₈ = A₁₆\n 8 = 1000₂ = 10₈ = 8₁₆\n\nChant: 10 in base b equals b.",
                        coachNote: "Sticky notes: four labels, same 15. Then ask 10₈ vs 10₁₆ before the recipe slide."
                    ),
SlideCard(
                        title: "The four bases ACSL uses — cheat sheet",
                        bullets: [
                            "You already met each world. This is the fridge-magnet version for the pencil case.",
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
                            "Now the recipe. Same boxes you already used: write places, multiply, add. This works in every base.",
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
                        title: "Do now · convert to decimal (2 min)",
                        bullets: [
                            "Silent. Place row under the digits. Then check the gray box.",
                            "Q1. 10110₂ to decimal.",
                            "Q2. 2C₁₆ to decimal. (C is 12.)",
                            "Q3. 15₈ to decimal, then write that value as hex."
                        ],
                        diagram: "Q1  16+4+2=22\nQ2  2×16+12=44\nQ3  1×8+5=13 = D₁₆",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
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
                        title: "Contest shape: hex → octal in one shot (via binary)",
                        bullets: [
                            "ACSL often asks: convert a hex number to octal. Do not go hex→decimal→octal unless the number is tiny. Use binary as the bridge.",
                            "Step 1: each hex digit → exactly 4 bits. 0=0000, 1=0001, … 9=1001, A=1010, B=1011, C=1100, D=1101, E=1110, F=1111.",
                            "Step 2: glue the bits. Step 3: regroup into 3s from the RIGHT. Pad LEFT with 0s if needed. Step 4: each trio is one octal digit 0–7.",
                            "Worked: 2F₁₆. 2=0010, F=1111 → 00101111. Groups of 3 from the right: 00 101 111 → 0 5 7 → 57₈. Drop a leading 0 if ACSL wants 57₈ not 057₈.",
                            "Worked: 1A₁₆. 1=0001, A=1010 → 00011010 → 000 110 10, pad left: 000 011 010 → 0 3 2 → 32₈. Check: 26₁₀ = 32₈."
                        ],
                        diagram: "2 F₁₆\n0010 1111\n  0 101 111     (groups of 3 from the right)\n  0   5   7  → 57₈\n\nCheck: 2F₁₆=47₁₀,  5×8+7=47. Yes.\n\nWrite the answer as 57 or 578 — match the contest blank. No 0o prefix.",
                        coachNote: "This is a top-5 ACSL Junior 1 item. Do two more live: 3C₁₆ and B₁₆."
                    ),
                    SlideCard(
                        title: "Contest shape: how many 1s in the binary of N?",
                        bullets: [
                            "Stem looks like: ‘How many 1’s are in the binary representation of 45?’ Convert, then COUNT the ones. Do not add the place values again.",
                            "45₁₀ = 101101₂. Digits: 1,0,1,1,0,1. There are four 1s. Answer: 4.",
                            "Shortcut: keep dividing by 2 and count how many remainders are 1. Same remainders as conversion.",
                            "Python check: format(45,'b').count('1') → 4. bin(45).count('1') also works (the 0b prefix has no 1s that matter... wait 0b has no 1. Fine). Prefer format.",
                            "Watch leading zeros: 00101101 still has four 1s. Padding does not add 1s."
                        ],
                        diagram: "45 → 101101₂ → four 1s → 4\n26 → 11010₂ → three 1s → 3\n15 → 1111₂ → four 1s → 4\n16 → 10000₂ → one 1 → 1\n\nPython:\nprint(format(45, 'b').count('1'))   # 4",
                        coachNote: "Have Soha convert 45 on paper then count with a finger. Then run the one-liner."
                    ),
                    SlideCard(
                        title: "Do now · hex↔octal and bit count (3 min)",
                        bullets: [
                            "Q1. Convert 3C₁₆ to octal using the binary bridge.",
                            "Q2. How many 1s in the binary of 26?",
                            "Q3. Write 47 as hex with no 0x prefix."
                        ],
                        diagram: "Q1  3=0011, C=1100 → 00111100 → 74₈\nQ2  26=11010₂ → three 1s → 3\nQ3  2F",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "How to write the short-answer (so the grader marks it)",
                        bullets: [
                            "Write only what the blank asks. No 0b, 0o, 0x prefixes. No Python quotes.",
                            "Binary: 101101 not 0b101101. Octal: 57 not 0o57. Hex: 2D or 2d — if they printed hex on samples as 2D, use uppercase.",
                            "If they ask ‘how many 1s’, the answer is a small decimal like 4, not the binary string.",
                            "If they ask two things (e.g. rhombuses AND segments), write both in the order asked, often with a comma or ‘and’ — copy the sample’s style.",
                            "Spaces: 4 3 as printed output vs 4,3. Match the problem. When in doubt, look at the sample output on programming; on short-answer, usually a single number."
                        ],
                        diagram: "Wanted          Write this       Not this\n47 decimal      47               47₁₀ or 0d47\n2D hex          2D               0x2d  or  '2D'\n57 octal        57               0o57\nfour 1-bits     4                101101\nprint 4 3       4 3              (4, 3)  or [4, 3]",
                        coachNote: "Put this table on a sticky note in the pencil case for contest day."
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
                        title: "Subtracting in another base (borrow, don’t panic)",
                        bullets: [
                            "Same as 2nd-grade subtraction, but a ‘borrow’ brings one full bundle of the BASE, not 10.",
                            "Binary: borrowing from the next column gives you 2 ones. 0−1 cannot; borrow, that 0 becomes 2, minus 1 is 1, and the next column drops by 1.",
                            "Hex: borrow brings 16. Example: 20₁₆ − 1A₁₆. Ones: 0−10 cannot; borrow from 2. Ones become 16−10=6. Left digit 1−1=0. Answer 6₁₆.",
                            "Safer method for Junior: convert both to decimal, subtract, convert back. Use this if borrowing feels messy. ACSL allows any correct method.",
                            "Worked binary: 1010₂ − 11₂. Decimal 10−3=7=111₂. Or borrow through the columns."
                        ],
                        diagram: "Hex:   2 0₁₆\n      − 1 A₁₆\n      -------\n        6₁₆     because 32−26=6\n\nBinary: 1 0 1 0     (10)\n      −     1 1     ( 3)\n      ---------     ---\n        1 1 1       ( 7)",
                        coachNote: "If borrowing melts them, bless the decimal bridge. Speed comes later; correctness first."
                    ),
                    SlideCard(
                        title: "Contest shape: multiply in another base (ACSL does this; no division)",
                        bullets: [
                            "ACSL Computer Number Systems includes addition, subtraction, AND multiplication in other bases. They do not ask you to divide in another base.",
                            "Same as 3rd-grade multiply: one digit at a time, then add the partial products. Carry when you hit the BASE, not 10.",
                            "Worked octal: 12₈ × 5₈. 2×5=10 decimal = 1×8+2, so write 2 carry 1. Then 1×5=5, plus carry 1 = 6. Answer 62₈.",
                            "Check in decimal: 12₈=10, 5₈=5, 10×5=50. 62₈=6×8+2=50. Same person, different outfit.",
                            "If the multiplier has two digits, do the ones digit first, then the eights (or sixteens) digit shifted one place left, then add in that base."
                        ],
                        diagram: "Octal:    1 2₈\n         ×     5₈\n         -------\n           6 2₈     2×5=10=12₈ write 2 carry 1; 1×5+1=6\n\nCheck: 10×5=50 and 6×8+2=50. Good.",
                        coachNote: "If multiply-in-base melts them, bless decimal: convert, multiply, convert back. ACSL accepts any correct method."
                    ),
                    SlideCard(
                        title: "Contest shape: fractions in binary / octal / hex",
                        bullets: [
                            "A point does not mean ‘decimal.’ It means the places go RIGHT of the point as 1/base, 1/base², 1/base³.",
                            "Binary: 0.1₂ = 1/2 = 0.5.  0.01₂ = 1/4 = 0.25.  0.11₂ = 1/2 + 1/4 = 0.75.",
                            "Octal: 0.4₈ = 4/8 = 0.5.  Hex: 0.8₁₆ = 8/16 = 0.5. Same value, different outfits.",
                            "To convert a binary fraction to decimal: list places 1/2, 1/4, 1/8, 1/16… under each bit after the point, multiply, add.",
                            "Integer part still uses 1, 2, 4, 8… to the LEFT. Example: 10.11₂ = 2 + 0.75 = 2.75."
                        ],
                        diagram: "0 . 1 1   in binary\n    1/2  1/4\n    0.5 + 0.25 = 0.75\n\n1 0 . 1    in binary\n2 + 0 + 0.5 = 2.5\n\n0.4₈ = 4/8 = 1/2",
                        coachNote: "Say ‘the point is a fence, not a decimal.’ Quiz 0.1₂ until they say one-half, not one-tenth."
                    ),
                    SlideCard(
                        title: "Contest shape: hex colors (#FF0000) — same hex, a picture",
                        bullets: [
                            "Wiki: screens mix red, green, blue. Each channel is two hex digits, 00 to FF, meaning 0 to 255.",
                            "#FF0000 is red (255, 0, 0). #00FF00 green. #0000FF blue. #000000 black. #FFFFFF white.",
                            "Salmon #FA8072: FA=250, 80=128, 72=114. Convert each pair as two hex digits.",
                            "If ACSL asks the decimal of FF16, that is 15 times 16 plus 15 = 255 — same arithmetic as number systems."
                        ],
                        diagram: "#FF0000  red   (255, 0, 0)\n#00FF00  green\n#0000FF  blue\nFF16 = 255 shades per channel",
                        coachNote: "One conversion, then move on. Do not teach CSS."
                    ),
                    SlideCard(
                        title: "Do now · arithmetic in other bases (3 min)",
                        bullets: [
                            "Q1. 12₈ × 5₈. Check in decimal.",
                            "Q2. 0.11₂ as a decimal fraction.",
                            "Q3. What decimal is the red channel of #FF0000?"
                        ],
                        diagram: "Q1  62₈  (10×5=50, 6×8+2=50)\nQ2  0.75\nQ3  255",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Drill until automatic: bits, octal triples, hex nybbles, powers",
                        bullets: [
                            "Octal digit → exactly 3 bits. Say them until they are songs: 0=000, 1=001, 2=010, 3=011, 4=100, 5=101, 6=110, 7=111.",
                            "Hex digit → exactly 4 bits (a nybble). 0=0000 … 9=1001, A=1010, B=1011, C=1100, D=1101, E=1110, F=1111.",
                            "Powers of 2 through 4096: 1,2,4,8,16,32,64,128,256,512,1024,2048,4096.",
                            "Powers of 8 through 4096: 1,8,64,512,4096.",
                            "Powers of 16 through 65536: 1,16,256,4096,65536.",
                            "ACSL will not ask negative binaries or two’s complement on this category. Skip that rabbit hole."
                        ],
                        diagram: "Octal 3-bit:  0=000 1=001 2=010 3=011\n               4=100 5=101 6=110 7=111\nHex 4-bit:     A=1010 B=1011 C=1100\n               D=1101 E=1110 F=1111\n2^n: 1 2 4 8 16 32 64 128 256 512 1024 2048 4096",
                        coachNote: "Flashcard 90 seconds every Week 2–4 homework check. No notes. Speed is a contest point."
                    ),
                    SlideCard(
                        title: "Week 3 homework · ~1 hour (due Sep 7)",
                        bullets: [
                            "Paper (30 min): 45→binary, 50→hex, 101101₂→octal by grouping, 1011₂+0110₂, 12₈×5₈, 0.11₂ to decimal.",
                            "Type (30 min): format(45,'b'), format(50,'X'), format(63,'o'). Plus int() check that grouping answers match.",
                            "Write ‘pad left’ on the grouping problem so you remember."
                        ],
                        diagram: "45 → 101101₂\\n50 → 32₁₆\\n101101₂ → 55₈\\n1011+0110 → 10001₂\\n12₈×5₈ = 62₈\\n0.11₂ = 0.75",
                        coachNote: "Collect grouping work. If they padded right, redo that one in the next homework-check."
                    ),
                    SlideCard(
                        title: "Week 4 · Sep 7 · meeting (90 min) · I/O + numbers checkpoint",
                        bullets: [
                            "0:00–0:15  Homework five. Quick grouping recap.",
                            "0:15–0:40  Mixed 5-problem number-systems drill (do now slide). Grade together.",
                            "0:40–0:55  Slow Python ears: input, text vs int, strip, split, cup 0 and cup 1. Do nows. Do not chain yet.",
                            "0:55–1:25  Lab: input() echo, then two-cup convert. Full program only if cups are solid.",
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
                        title: "Contest shape: counting in two bases at once",
                        bullets: [
                            "Wiki sample: how many numbers from 100 to 200 (decimal) have distinct ascending digits AND distinct ascending hex digits?",
                            "Ascending means each digit is bigger than the one on its left: 123 yes, 132 no, 122 no (not distinct).",
                            "Method: list candidates with ascending decimal digits in 100 to 200, convert each to hex, check hex digits too.",
                            "Wiki answer: 13 numbers. List, do not memorize: 123 (7B) through 127 (7F), 137-139, 156-159, 189 (BD).",
                            "This is still number systems: convert, then look at digits. Slow and neat beats clever."
                        ],
                        diagram: "12310 = 7B16   both ascending\n13210 = 8416   decimal not ascending\nWiki count in 100..200: 13",
                        coachNote: "Do 123 and 189 as a class. The full list is optional stretch, not Week 3 required."
                    ),
                                        SlideCard(
                        title: "Python recap before the grader — what we already know",
                        bullets: [
                            "Week 1: print() talks. Quotes make text. n = 7 puts a number in a box named n.",
                            "Week 2: int('7') turns the TEXT seven into the NUMBER seven. int('1A', 16) does a base conversion.",
                            "You have not yet made a program that LISTENS. So far you typed the number inside the file. The contest computer types the number FOR you, after you press Run.",
                            "The next slides add one tiny skill at a time: listen, peel Enter, chop on spaces, name the pieces. We will not chain them until each piece is boring.",
                            "If print and int still feel mushy, stop and redo the 6-line program. Do not open input() yet."
                        ],
                        diagram: "Already know:\n  print(3+4)           → 7\n  n = 10\n  print(int('1A', 16)) → 26\n\nNot yet:\n  a line that arrives FROM OUTSIDE the file",
                        coachNote: "Hold up the 6-line program. ‘Tonight we add ears. Same mouth (print).’"
                    ),
                    SlideCard(
                        title: "Python: input() — the program waits for one line",
                        bullets: [
                            "input() means: pause. Wait for a line of typing. When Enter is pressed, give me that line as TEXT.",
                            "On your laptop, YOU type the line. On ACSL HackerRank, a hidden robot types it. Same function.",
                            "Always save it in a box: line = input()",
                            "Then you may print it back to see it: print(line). That is a practice trick. The real contest program will not echo the line — it will compute and print only the answer.",
                            "Do not write input('Enter a number:'). Those extra words get mixed into the robot’s output and the hidden tests fail."
                        ],
                        diagram: "line = input()\nprint(line)\n\nIf you type:  hello\nYou see:     hello\n\nIf you type:  1A 16\nYou see:     1A 16\n\n# Never:\n# input('Type here: ')   extra words fail ACSL",
                        coachNote: "Run this live. Type 1A 16. Celebrate that the program waited. That is the whole slide."
                    ),
                    SlideCard(
                        title: "Python: input() always gives TEXT, even if it looks like a number",
                        bullets: [
                            "If the person types 7, input() gives the TEXT '7', not the number 7. Same trap as Week 1 quotes.",
                            "Text cannot do math the way you want: '7' + '1' is 71 (glued). You need int(line) to get 8 from 7+1.",
                            "Worked: line = input()   (they type 7)   n = int(line)   print(n + 1)  → 8.",
                            "If they type 1A, int(line) crashes — 1A is not a decimal number. Hex still needs int(line, 16).",
                            "Habit: the moment you need math, wrap int(…)."
                        ],
                        diagram: "line = input()        # they type 7\nprint(line + '1')     # 71   glued text. Wrong for math.\nprint(int(line) + 1)  # 8    numbers. Right.\n\n# Hex later:\n# int('1A', 16) → 26",
                        coachNote: "Type 7 live. Show 71 vs 8. Same Week 1 joke, now with input()."
                    ),
                    SlideCard(
                        title: "Do now · input() is text (2 min)",
                        bullets: [
                            "Predict, then we run it.",
                            "Q1. line = input()  (you type 10). print(line + line). What appears?",
                            "Q2. Same typing. print(int(line) + int(line)). What appears?",
                            "Q3. Why is input('Enter:') dangerous on ACSL?"
                        ],
                        diagram: "Q1  1010   (text glued)\nQ2  20     (math)\nQ3  the word Enter: gets printed and hidden tests fail",
                        coachNote: "Cover the box. If Q1 is 20, they skipped the text lesson."
                    ),
                    SlideCard(
                        title: "Python: strip() — peel the leftover Enter and spaces",
                        bullets: [
                            "When you press Enter, a hidden ‘end of line’ character rides along. Sometimes extra spaces do too.",
                            ".strip() peels spaces and Enter from BOTH ends. It does not change letters in the middle.",
                            "Always: line = input().strip()   not bare input() for contest work.",
                            "'  7  '.strip() is '7'.  Then int(line) works. Without strip, some graders still pass — until a hidden test has a space and yours fails.",
                            "Say it: ‘strip the edges, keep the middle.’"
                        ],
                        diagram: "line = input().strip()\n\nTyped:   [space] 7 [space] [Enter]\nAfter strip:  '7'\nint(line) + 1  →  8\n\n'  1A 16  '.strip()  →  '1A 16'\n(the space BETWEEN 1A and 16 stays — we want that)",
                        coachNote: "Show a sticky note with spaces drawn on both ends. Tear them off. Middle stays."
                    ),
                    SlideCard(
                        title: "Python: split() — chop one line into a row of pieces",
                        bullets: [
                            "Contest lines often have TWO things: a numeral and a base, with a space: 1A 16",
                            ".split() with empty parentheses chops on any run of spaces. You get a ROW of pieces, called a list.",
                            "'1A 16'.split() → two pieces: 1A  and  16.",
                            "A list is a numbered row of boxes. The first box is number 0. The second is number 1. (Computers start counting at 0.)",
                            "We are not looping yet. We only pick box 0 and box 1 by hand."
                        ],
                        diagram: "line = '1A 16'\npieces = line.split()\n\n  box 0     box 1\n  '1A'      '16'\n\npieces[0]  is  '1A'    the numeral (still text)\npieces[1]  is  '16'    the base (still text!)",
                        coachNote: "Two paper cups labeled 0 and 1. Drop '1A' in 0, '16' in 1. Say pieces-sub-zero."
                    ),
                    SlideCard(
                        title: "Python: pieces[0] and pieces[1] — pick a cup, then int() if it is math",
                        bullets: [
                            "pieces[0] is the first word. pieces[1] is the second. Square brackets mean ‘which cup.’",
                            "Both cups still hold TEXT. The base 16 is the text '16' until int(pieces[1]).",
                            "The numeral '1A' stays text because int() needs that string PLUS the base: int(pieces[0], int(pieces[1])).",
                            "Chant: first cup numeral, second cup base, int the base, then int(numeral, base).",
                            "If there is only one number on the line, there is no cup 1. That is a different problem shape — later."
                        ],
                        diagram: "pieces = '1A 16'.split()\nnumeral = pieces[0]           # '1A'\nbase = int(pieces[1])         # 16  (now a number)\nprint(int(numeral, base))     # 26\n\n# Cups:\n#  0: 1A     1: 16",
                        coachNote: "Finger on [0] then [1]. Mix-up of cups is the #1 Week 4 bug."
                    ),
                    SlideCard(
                        title: "Do now · two cups (2 min)",
                        bullets: [
                            "line = '77 8'. pieces = line.split()",
                            "Q1. What is in pieces[0]? (quotes if it is text)",
                            "Q2. What is int(pieces[1])?",
                            "Q3. What does print(int(pieces[0], int(pieces[1]))) show?"
                        ],
                        diagram: "Q1  '77'\nQ2  8\nQ3  63     because 7×8+7=63",
                        coachNote: "If Q3 is 778 they glued text. Redo int()."
                    ),
SlideCard(
                        title: "Python: input().strip().split() — how the grader talks to your program",
                        bullets: [
                            "Now we SNAP the pieces together. You already met input, strip, split, and cups 0 and 1. This is the same story on four lines.",
                            "line = input().strip()     listen and peel Enter.",
                            "parts = line.split()       two cups.",
                            "print(int(parts[0], int(parts[1])))     convert and speak only the answer.",
                            "The hidden robot types 1A 16. Your program prints 26 and stops. No hello, no ‘the answer is’.",
                            "Name the list parts or pieces — either is fine. Do not skip strip."
                        ],
                        diagram: "Typed by the grader (you never see a person):\n1A 16\n\nline = input().strip()     # '1A 16'\nparts = line.split()       # ['1A', '16']\nnumeral = parts[0]         # '1A'\nbase = int(parts[1])       # 16\nprint(int(numeral, base))  # 26\n\n# NEVER:\n# input('Enter a number:')  ← extra words fail hidden tests",
                        coachNote: "Walk index 0 and 1 with fingers. Middle schoolers mix up which piece is the base. Chant: ‘first token numeral, second token base.’"
                    ),
                                        SlideCard(
                        title: "Python: first conversion program — four lines, no import yet",
                        bullets: [
                            "Type this together. No def, no import sys, no if __name__. Those come after this works.",
                            "Run it. When it waits, type 2F 16 and Enter. You want 47.",
                            "Run again. Type 77 8. You want 63. Type 1011 2. You want 11.",
                            "If you see 2F16 glued, split did not run. If you see an error on 2F, you called int(parts[0]) without the base.",
                            "When these three samples work, you have the contest skill. The next slide is the same idea dressed up for HackerRank files."
                        ],
                        diagram: "line = input().strip()\nparts = line.split()\nnumeral = parts[0]\nbase = int(parts[1])\nprint(int(numeral, base))\n\n# type 2F 16  →  47\n# type 77 8   →  63\n# type 1011 2 →  11",
                        coachNote: "Do not open import sys until 47 appears. One victory, then the fancy file."
                    ),
                    SlideCard(
                        title: "Python: smallest function — type hello() together",
                        bullets: [
                            "Pause conversion. Four new words: def, colon, indent, call.",
                            "Type this exactly. hello() at the bottom is the CALL — that is what makes hi appear.",
                            "If you only type def and press Run, the screen stays blank. The recipe sits on a shelf until you call it.",
                            "Empty () means the recipe needs no ingredients. Indent print with 4 spaces so it belongs to hello."
                        ],
                        diagram: "def hello():\n    print('hi')\n\nhello()     # hi\nhello()     # hi again\n\n# Skip the hello() lines → nothing prints.",
                        coachNote: "Run with no call (blank). Then add hello(). That is the whole lesson."
                    ),
                    SlideCard(
                        title: "Python: one number in the parentheses",
                        bullets: [
                            "The recipe needs one number. We name the box n. show(5) puts 5 in n.",
                            "Type this. You should see 10, then 6.",
                            "n exists only inside the recipe. After it finishes, n is gone. That is OK.",
                            "This version only prints. Next we hand a value back with return."
                        ],
                        diagram: "def show(n):\n    print(n * 2)\n\nshow(5)    # 10\nshow(3)    # 6\n\n# show() empty → error. It wanted a number.",
                        coachNote: "Call show(5) and show(3). Then try empty show() and read the error."
                    ),
                    SlideCard(
                        title: "Python: two numbers — add(a, b)",
                        bullets: [
                            "Two boxes, comma between. add(3, 4) puts 3 in a and 4 in b.",
                            "Type it. You want 7, then 10.",
                            "Order is the order in the parentheses: first listed, first box."
                        ],
                        diagram: "def add(a, b):\n    print(a + b)\n\nadd(3, 4)     # 7\nadd(6, 4)     # 10",
                        coachNote: "Ask Soha for add(2, 8) before you type it."
                    ),
                    SlideCard(
                        title: "Python: a function is a named recipe you can reuse",
                        bullets: [
                            "So far every line runs from top to bottom, once. A function is a recipe with a NAME. You write it once. You use it later by saying the name.",
                            "Real life: ‘double this’ is a recipe. You can double 5, then later double 10, without rewriting the steps.",
                            "Python’s word for the recipe title is def (short for define). The body is indented, same idea as later if-blocks.",
                            "Nothing in the recipe runs until you CALL it: write the name with parentheses. def only files the recipe on the shelf.",
                            "We will do tiny recipes first (double a number). Then we wrap the conversion program in a recipe named solve."
                        ],
                        diagram: "Shelf:  recipes we defined\n  double\n  solve     (later)\n\nCalling:  double(5)  means ‘run the double recipe on 5’\nDefining without calling does NOTHING on the screen.",
                        coachNote: "Physical: write ‘double’ on a card. Put it on a shelf. Nothing happens until you pick it up and say double-five."
                    ),
                    SlideCard(
                        title: "Python: def, colon, indent — writing the recipe",
                        bullets: [
                            "def double(n):  means: the recipe is named double. It needs one ingredient, a box named n.",
                            "The colon : at the end of that line is required. Next lines that belong to the recipe are indented (4 spaces).",
                            "return n * 2  means: the answer of this recipe is twice n. Hand that value back to whoever called us.",
                            "print talks to the screen. return talks to the rest of the program. Contest code almost always return the number, then print once outside.",
                            "Call it: print(double(5)). Python puts 5 in n, computes 10, return 10, print shows 10."
                        ],
                        diagram: "def double(n):\n    return n * 2\n\nprint(double(5))    # 10\nprint(double(8))    # 16\nprint(double(0))    # 0\n\n# Forgot to call:\ndef double(n):\n    return n * 2\n# (no print)  → screen stays blank. Recipe is only on the shelf.",
                        coachNote: "Type double together. Call it three times. Then comment out the print and show the blank screen."
                    ),
                    SlideCard(
                        title: "Python: return vs print inside a function (first look)",
                        bullets: [
                            "If the recipe print(n*2) and you write x = double(5), x is empty (None). The 10 went to the screen, not into x.",
                            "If the recipe return n*2, then x = double(5) puts 10 in x. You can print(x) or use it in math.",
                            "ACSL: compute with return. Speak to the grader with one print at the end.",
                            "You may print inside a function while debugging. Take those prints OUT before submit.",
                            "Week 5 will hit this again with recursion. Learn the slogan now: return the value, print the answer."
                        ],
                        diagram: "def shown(n):\n    print(n * 2)     # talks to screen\n\ndef given(n):\n    return n * 2     # hands value back\n\nx = given(5)\nprint(x)             # 10\n\n# x = shown(5)  → x is None, and 10 already printed",
                        coachNote: "Two columns on the board: SCREEN vs HAND BACK."
                    ),
                    SlideCard(
                        title: "Do now · a tiny function (2 min)",
                        bullets: [
                            "Q1. What does print(double(6)) show if def double(n): return n*2?",
                            "Q2. If you write def double(n): return n*2  and never call it, what appears on the screen?",
                            "Q3. add(a, b) should hand back a+b. Which is right: return a+b  or  print(a+b)  if we want x = add(3,4) to be 7?"
                        ],
                        diagram: "Q1  12\nQ2  nothing  (recipe on the shelf only)\nQ3  return a+b",
                        coachNote: "If Q2 is 0 or error, they think def runs immediately."
                    ),
                    SlideCard(
                        title: "Python: wrap our conversion in def solve()",
                        bullets: [
                            "Same four-line program, now inside a recipe. The ingredient list is empty: solve() needs nothing from the parentheses because input() listens inside.",
                            "return the number. Outside: print(solve()). One print, one number, grader is happy.",
                            "Why bother? HackerRank samples sometimes say ‘implement solve’. Also you can test solve() later with fake input. For now it is just a named box around code we already trust.",
                            "Type this only after the no-def four-liner already printed 47."
                        ],
                        diagram: "def solve():\n    line = input().strip()\n    parts = line.split()\n    numeral = parts[0]\n    base = int(parts[1])\n    return int(numeral, base)\n\nprint(solve())\n\n# type 2F 16  →  47",
                        coachNote: "Copy the four lines into the indent. Missed indent is the usual crash."
                    ),
                    SlideCard(
                        title: "Python: import sys — borrow a toolbox (optional dress-up)",
                        bullets: [
                            "import sys means: borrow Python’s sys toolbox. We need it for sys.stdin — ‘everything the robot typed, not just one line.’",
                            "sys.stdin.read() reads ALL leftover typing at once. .strip().split() then makes one long row of cups, including blank-line problems.",
                            "One line of input: input() is enough. Many lines or mystery blank lines: stdin.read() is sturdier.",
                            "You do not need if __name__ == '__main__' to score. That line means ‘only auto-run when this file is the program, not when someone imports it.’ Skip it in middle school unless the template already has it.",
                            "Next slide is the dressed-up file. Same math as 47. New wrapper only."
                        ],
                        diagram: "import sys\nparts = sys.stdin.read().strip().split()\n# cups: whatever the robot typed, split on spaces\n\n# One line still works:\n# input().strip().split()",
                        coachNote: "If import scares them, stay on print(solve()) with input(). The wrapper is not the skill."
                    ),
SlideCard(
                        title: "Python: a complete Contest 1 conversion program (type this)",
                        bullets: [
                            "Same conversion you already ran. Now it may use def solve and stdin. If import still feels loud, keep last slide’s print(solve()) with input().",
                            "return the int from solve. print(solve()) once. No extra words.",
                            "The if __name__ block is optional dress-up. You may delete it and just print(solve()) at the bottom.",
                            "Check: 2F 16 → 47 still. If that fails, the wrapper is wrong, not the math."
                        ],
                        diagram: "import sys\n\ndef solve():\n    parts = sys.stdin.read().strip().split()\n    numeral = parts[0]\n    base = int(parts[1])\n    return int(numeral, base)\n\nprint(solve())\n\n# 2F 16 → 47   (same as the four-liner)\n# Sample: stdin  1011 2  → prints 11\n# Sample: stdin  77 8    → prints 63",
                        coachNote: "Have Soha change only the sample in her head: ‘If I type 77 8, what prints?’ Wait for 63. Then run it."
                    ),
                    SlideCard(
                        title: "Python: several cases — T, then T lines",
                        bullets: [
                            "Some programming problems start with an integer T (how many test cases), then T lines of data.",
                            "Read T first. Then loop exactly T times. Print one answer per case, each on its own line.",
                            "sys.stdin.read().split() still works: first token is T, then the rest come in groups.",
                            "Do not print ‘Case 1:’. Print only the answers, one per line, unless the spec says otherwise."
                        ],
                        diagram: "stdin:\n3\n1A 16\n1011 2\n77 8\n\nparts = sys.stdin.read().split()\nT = int(parts[0])\ni = 1\nfor _ in range(T):\n    numeral = parts[i]\n    base = int(parts[i+1])\n    print(int(numeral, base))\n    i += 2\n\n# prints:\n# 26\n# 11\n# 63",
                        coachNote: "Walk the index i with a finger: after T, pairs of (numeral, base). Off-by-one here fails all hidden tests."
                    ),
                    SlideCard(
                        title: "Python: Contest 1 programming is not always ‘convert’",
                        bullets: [
                            "The programming problem is its own story. It might be: read n, if n is even do this, else do that, maybe repeat a formula. Read the spec twice.",
                            "Pattern: parse ints, then BRANCH (if/else), maybe a tiny loop or a recursive function, then print one number.",
                            "Example spec: ‘If n is even, replace n with n/2. If odd, replace with 3n+1. Do this once. Print n.’ That is Collatz-one-step — branching, not conversion.",
                            "Example: ‘Read a and b. Print the larger. If tied, print 0.’ Pure if/else.",
                            "Match return type: int vs str. If they want YES/NO, print those exact letters."
                        ],
                        diagram: "n = int(input().strip())\nif n % 2 == 0:\n    n = n // 2\nelse:\n    n = 3 * n + 1\nprint(n)\n\n# 5 → 16    10 → 5\n\na, b = map(int, input().split())\nif a > b:\n    print(a)\nelif b > a:\n    print(b)\nelse:\n    print(0)",
                        coachNote: "After conversion labs, do these two as a palate cleanser so they do not freeze when HackerRank is not a base conversion."
                    ),
                    SlideCard(
                        title: "Contest shape: the programming problem is 72 hours, not 5 mini-tests in the room",
                        bullets: [
                            "Junior Contest 1 short-answer is a sitting of 6 questions. The Python problem is SEPARATE: one HackerRank problem, about 72 hours to submit.",
                            "You still practice hidden tests here because THAT is how HackerRank grades: exact stdout, several secret cases.",
                            "Read the full problem: input format, sample, what to print. Then write one program that handles every case, including T then T lines if they use that.",
                            "Submit, read the score, fix, resubmit inside the window. Do not wait until hour 71.",
                            "Tracker in this app: programming 0–5 is the HackerRank score. Short-answer 0–5 is the paper (6 questions, 5 points)."
                        ],
                        diagram: "Paper day:  6 questions, 2 per topic, 5 pts\nThen ~72 hours: 1 program on HackerRank, 5 pts\n\nThis app’s Python tab = practice the hidden-test habit.",
                        coachNote: "Do not scare them with 72 hours of coding. It is one problem, started the evening of the paper."
                    ),
                    SlideCard(
                        title: "Python: % means remainder — even, odd, last digit",
                        bullets: [
                            "% is not percent here. a % b is the remainder when a is divided by b.",
                            "n % 2 == 0 means n is even. n % 2 == 1 means odd. This shows up in recursion AND in if-tracing AND in programming.",
                            "n % 10 is the last decimal digit. 47 % 10 is 7.",
                            "// is whole-number divide: 5 // 2 is 2. 5 / 2 in Python 3 is 2.5 — ACSL almost always wants //."
                        ],
                        diagram: "print(5 % 2)    # 1  odd\nprint(6 % 2)    # 0  even\nprint(47 % 10)  # 7\nprint(5 // 2)   # 2\nprint(5 / 2)    # 2.5  ← usually wrong for ACSL ints",
                        coachNote: "Chant: ‘percent remainder, slash-slash whole divide.’"
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
                            "0:15–0:55  Recursion English. First rows 0–2 freeze. Table through 4. Simple do-now. Piecewise only if the table is solid.",
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
                        title: "Same function idea — the recipe now calls itself",
                        bullets: [
                            "Last week, double(n) used n and stopped. Recursion is a recipe that uses its OWN name, on a SMALLER number.",
                            "f(4) asks f(3). f(3) asks f(2). That would never end unless someone says STOP. The stop is the base case: f(0) is given.",
                            "You already know def, return, and calling f(5). Recursion is those skills plus ‘call f with a smaller n’ plus ‘stop at 0.’",
                            "On the contest you usually do not think about the stack of calls. You fill a table from 0 upward. Same answers."
                        ],
                        diagram: "double(5)  →  10     (does not call double again)\n\nf(4) → needs f(3)\nf(3) → needs f(2)\nf(2) → needs f(1)\nf(1) → needs f(0)\nf(0) = 1     STOP, given",
                        coachNote: "Point at hello() then at f. ‘Same def. New trick: the recipe says its own name.’"
                    ),
                    SlideCard(
                        title: "Build the first rows — only f(0), then f(1), then f(2)",
                        bullets: [
                            "Rule: f(0)=1.  When n>0, f(n)= n + f(n-1). Addition, not multiply.",
                            "Row 0: they gave us 1. Write it. Do not invent f(0)=0.",
                            "Row 1: n=1, so 1 + f(0) = 1+1 = 2. You only needed the row above.",
                            "Row 2: n=2, so 2 + f(1) = 2+2 = 4.",
                            "If you feel lost, you skipped a row. Go back one n. Never jump to f(4) in your head tonight."
                        ],
                        diagram: "n | f(n) | what I wrote\n0 |  1   | given. stop.\n1 |  2   | 1 + f(0) = 1+1\n2 |  4   | 2 + f(1) = 2+2\n\nStop here. Check with a neighbor. Then we add rows 3 and 4.",
                        coachNote: "Freeze after f(2). Three volunteers: row 0, 1, 2. Then continue."
                    ),
                    SlideCard(
                        title: "Rows 3 and 4 — still only the row above",
                        bullets: [
                            "Row 3: 3 + f(2) = 3+4 = 7.",
                            "Row 4: 4 + f(3) = 4+7 = 11.",
                            "If they ask f(4), box 11. If they ask f(3), box 7. Copy the n they asked, not the last number you like.",
                            "Common miss: multiplying (1,1,2,6,24) — that is factorial, a different recipe. Ours adds.",
                            "Another miss: starting at n=1 as the first row and then calling that f(4) when you have four scribbles."
                        ],
                        diagram: "n | f(n)\n0 |  1\n1 |  2\n2 |  4\n3 |  7     3+4\n4 | 11     4+7   ← f(4)\n5 | 16     5+11\n6 | 22     6+16",
                        coachNote: "Ask f(4) and wait for 11. Then ask f(3) on purpose so they do not always grab the bottom."
                    ),
                    SlideCard(
                        title: "Do now · one simple table (3 min)",
                        bullets: [
                            "Same rule: f(0)=1, f(n)=n+f(n-1). Silent. Fill n=0 through 5.",
                            "Q1. f(5)",
                            "Q2. f(2)",
                            "Q3. True or false: f(5) is 5×f(4)."
                        ],
                        diagram: "Q1 16\nQ2 4\nQ3 false  (it is 5 PLUS f(4), so 5+11=16)",
                        coachNote: "If Q3 is true they are in factorial land. Rebuild row 5 together."
                    ),
                    SlideCard(
                        title: "How ACSL writes the rule — two lines, read the stop first",
                        bullets: [
                            "They print a curly two-line recipe. Line A is often the recursive case. Line B is the stop. Read BOTH before you compute.",
                            "Always find the stop first: which n (or which test) does NOT call f again?",
                            "Then: start at the n they asked. Apply the matching line. Write the new call. Repeat until stop. Then add/multiply backward, or use a table from the stop upward.",
                            "If two numbers are ‘given’ (Fibonacci), you have TWO stop rows. Fill both before the recipe that uses n-1 and n-2."
                        ],
                        diagram: "They write:\n  f(n) = n + f(n-1)    if n > 0\n       = 1             if n = 0\n\nYou write:\n  stop: f(0)=1\n  then table upward.",
                        coachNote: "Cover the recursive line. ‘Where do we stop?’ Then uncover."
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
                        title: "Unfolding f(3) once — then we go back to the table",
                        bullets: [
                            "Some people like to write f(3)=3+f(2)=3+2+f(1)=3+2+1+f(0)=3+2+1+1=7. That is legal.",
                            "It gets messy at f(7). The table is the same work, neater, harder to drop a plus.",
                            "Contest habit: table. Unfolding is only to see why the table is allowed.",
                            "If you unfold, you must still hit the stop. Forgetting f(0)=1 gives a chain that never ends."
                        ],
                        diagram: "Unfold:\nf(3)=3+f(2)\n    =3+2+f(1)\n    =3+2+1+f(0)\n    =3+2+1+1=7\n\nTable (same 7):\n0→1, 1→2, 2→4, 3→7",
                        coachNote: "One unfold on the board. Then ‘we will not do this for f(12). Table.’"
                    ),
SlideCard(
                        title: "Contest shape: piecewise f(x) with several cutoffs",
                        bullets: [
                            "ACSL recursive functions often look like a stacked rule: different formulas depending on how big x is.",
                            "Always start at the GIVEN x. Ask: which piece applies? Compute, that gives a smaller call, repeat until a base piece that does not call f.",
                            "Example: f(x)= f(x−2)−3  if x≥10;  f(x)= f(x−2)+4 if 3≤x<10;  f(x)= x+7 if x<3.",
                            "Find f(12): 12≥10 so f(12)=f(10)−3. 10≥10 so f(10)=f(8)−3. 8 is between 3 and 10 so f(8)=f(6)+4. Keep going until x<3.",
                            "Write a downward chain, then substitute backward. Do not skip which piece you used."
                        ],
                        diagram: "f(x) = f(x-2)-3    if x ≥ 10\n     = f(x-2)+4    if 3 ≤ x < 10\n     = x+7         if x < 3\n\nf(12)= f(10)-3\nf(10)= f(8)-3\nf(8) = f(6)+4\nf(6) = f(4)+4\nf(4) = f(2)+4\nf(2) = 2+7 = 9     ← base\nThen back: f(4)=13, f(6)=17, f(8)=21, f(10)=18, f(12)=15",
                        coachNote: "Box the piece used next to each line. The cutoff mistakes are all ‘I used the wrong band.’"
                    ),
                    SlideCard(
                        title: "Nested calls: f(f(n)) — inside first",
                        bullets: [
                            "f(f(3)) means: first find f(3), then plug that NUMBER into f again.",
                            "Never ‘do f twice in your head at once.’ Two table lookups.",
                            "If f(0)=1, f(n)=n+f(n−1), then f(3)=7, so f(f(3))=f(7). Now you need the table out to 7.",
                            "Python: return f(f(n-1)) is legal but you still need a base case. On paper, evaluate inside parentheses first — same as math class."
                        ],
                        diagram: "Table: n 0 1 2 3 4 5 6 7\n     f 1 2 4 7 11 16 22 29\n\nf(f(3)) = f(7) = 29\nf(f(0)) = f(1) = 2\nf(f(1)) = f(2) = 4",
                        coachNote: "Have them compute f(3) out loud, write 7 on a sticky, then look up f(7). Physical two steps."
                    ),
                    SlideCard(
                        title: "Do now · nested f(f(n)) (3 min)",
                        bullets: [
                            "f(0)=1, f(n)=n+f(n-1). Fill the table through 6 first.",
                            "Q1. f(4)",
                            "Q2. f(f(2))  — inside first.",
                            "Q3. f(f(3))"
                        ],
                        diagram: "Table n=0..6: 1,2,4,7,11,16,22\nQ1 11\nQ2 f(2)=4, f(4)=11\nQ3 f(3)=7, f(7)=29",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Contest shape: pattern / stage recursion (drawings)",
                        bullets: [
                            "Some Junior 1 problems are pictures: Stage 1 is a shape. Each new stage adds copies by a rule. They ask ‘how many segments after Stage 6?’",
                            "Method: make a table Stage | count. Fill Stage 1 from the problem. Stage 2 from the problem. Find WHAT WAS ADDED each time.",
                            "If the add-on is constant (always +8 segments), it is arithmetic: next = previous + 8.",
                            "If the add-on itself grows, write a second column ‘new this stage’ and a third ‘total’.",
                            "Do not skip to Stage 6 in your head. Fill 1 through 6. ACSL samples do this (rhombus / perimeter problems)."
                        ],
                        diagram: "Example: Stage 1: 4 segments\nEach later stage adds 8 more segments.\n\nStage | new | total\n  1   |  4  |  4\n  2   |  8  | 12\n  3   |  8  | 20\n  4   |  8  | 28\n  5   |  8  | 36\n  6   |  8  | 44     ← asked\n\nIf NEW grows (4,8,12,16…), add a ‘new’ column that goes up by 4.",
                        coachNote: "If they freeze on the art, say: ‘Ignore the pretty picture. Steal the numbers they already computed for Stage 1–3, then continue the table.’"
                    ),
                                        SlideCard(
                        title: "Python: if only as a STOP — not the full if/else unit yet",
                        bullets: [
                            "Week 7 is hallway if/else. Tonight we need one tiny if: ‘if we are at the stop, return the given number.’",
                            "if n == 0:  means ‘if n is equal to 0.’ Two equals. Then indent the return 1.",
                            "The other return (the one that calls f(n-1)) is NOT in that indent. It runs when n is not 0.",
                            "We are not tracing two hallways. We are labeling STOP vs KEEP GOING.",
                            "If you write if n = 0 with one equals, Python errors. == asks. = puts in a box."
                        ],
                        diagram: "if n == 0:\n    return 1      # STOP\nreturn n + f(n-1) # KEEP GOING (not indented under the if)\n\n# == asks  ‘is n zero?’\n# =  puts  ‘make n zero’  ← wrong here",
                        coachNote: "Cover the keep-going line. ‘What happens at 0?’ Then uncover. Do not open elif tonight."
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
                        title: "Forgot the stop — paper never ends, Python RecursionError",
                        bullets: [
                            "If the recipe always calls f(n-1) and never has if n==0, the chain has no floor.",
                            "On paper that is an infinite scribble. You never get a number to box.",
                            "In Python: RecursionError: maximum recursion depth exceeded. Too many nested calls.",
                            "Fix: a base case that RETURNS a number and does not call f.",
                            "Wrong stop is also a bug: if n==1: return 1 when the paper said f(0)=1 will shift every later row."
                        ],
                        diagram: "Missing stop:\ndef f(n):\n    return n + f(n-1)\n# f(3) → f(2) → f(1) → f(0) → f(-1) → … boom\n\nWrong stop:\nif n == 1: return 1   # skips the f(0)=1 row",
                        coachNote: "Run the missing-stop version once if the lab is open. Then add the if. Same 30-second demo every year."
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
                        title: "Do now · multiply-and-add table (2 min)",
                        bullets: [
                            "f(0)=2, f(n)=n×f(n-1)+1.",
                            "Q1. f(1)",
                            "Q2. f(3)",
                            "Q3. If they ask f(3), is 89 the answer?"
                        ],
                        diagram: "Q1 3\nQ2 22\nQ3 no  — 89 is f(4)",
                        coachNote: "The 89 trap is the same as 17 vs 33 later."
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
                        title: "Even/odd — check EACH row, then use that row’s rule",
                        bullets: [
                            "f(0)=0. If n even: f(n)=f(n-1)+n. If n odd: f(n)=f(n-1)-1.",
                            "Even means n%2==0, or n is in 2,4,6,8… Odd: 1,3,5,7… Check the NEW n every row. Do not pick one rule for the whole table.",
                            "n=1 odd: f(0)-1 = 0-1 = -1. Negatives are allowed.",
                            "n=2 even: f(1)+2 = -1+2 = 1.",
                            "n=3 odd: f(2)-1 = 1-1 = 0."
                        ],
                        diagram: "n | even? | f(n)\n0 | stop  |  0\n1 | odd   | -1     f(0)-1\n2 | even  |  1     f(1)+2\n3 | odd   |  0     f(2)-1\n4 | even  |  4     f(3)+4",
                        coachNote: "Write EVEN/ODD in the middle column every time. The miss is using +n on an odd row."
                    ),
                    SlideCard(
                        title: "Do now · even/odd table (3 min)",
                        bullets: [
                            "Same rule as the last slide. Fill through n=4.",
                            "Q1. f(2)",
                            "Q2. f(4)",
                            "Q3. Did n=3 use +n or −1?"
                        ],
                        diagram: "Q1 1\nQ2 4\nQ3 −1  (odd)",
                        coachNote: "If Q2 is 6 they added 4 to f(2) and skipped a row."
                    ),
                    SlideCard(
                        title: "Two-argument grid — fill edges, then left plus above",
                        bullets: [
                            "f(x,y)=f(x-1,y)+f(x,y-1), and if x=0 or y=0 then f=1. Two ingredients, like add(a,b), but it calls itself.",
                            "Do not recurse in your head. Draw a grid. x down, y across.",
                            "Fill the whole 0-row with 1s. Fill the whole 0-column with 1s. Those are the stops.",
                            "Each empty square = LEFT neighbor + ABOVE neighbor. Walk left-to-right, top-to-bottom.",
                            "f(2,2) is the square at row x=2, column y=2. After filling, it is 6."
                        ],
                        diagram: "       y=0  y=1  y=2\n x=0    1    1    1\n x=1    1    2    3\n x=2    1    3    6\n\n2 = 1+1 (left+above)\n3 = 2+1\n6 = 3+3",
                        coachNote: "Empty grid on the projector. Class calls out each interior square."
                    ),
                    SlideCard(
                        title: "Do now · grid f(2,2) (3 min)",
                        bullets: [
                            "Same edge-1 grid. Fill it.",
                            "Q1. f(1,1)",
                            "Q2. f(2,1)",
                            "Q3. f(2,2)"
                        ],
                        diagram: "Q1 2\nQ2 3\nQ3 6",
                        coachNote: "If they say f(2,2)=4 they added 2+2 from the rule in their head."
                    ),
SlideCard(
                        title: "Contest shape: named recipes — factorial and Fibonacci",
                        bullets: [
                            "ACSL recursive-functions wiki starts with names you may hear: factorial and Fibonacci. Same table method.",
                            "Factorial: f(0)=1, f(n)=n×f(n-1). Rows: 1, 1, 2, 6, 24, 120… That is 0!, 1!, 2!, 3!, 4!, 5!.",
                            "Fibonacci: f(0)=0, f(1)=1, f(n)=f(n-1)+f(n-2). Rows: 0,1,1,2,3,5,8,13… Need TWO previous numbers.",
                            "Contest problems often do NOT use the names. They give the two rules. If they do say Fibonacci, still fill the table — do not recite from memory past f(10) unless you wrote it."
                        ],
                        diagram: "n! :  n  0 1 2 3  4   5\n       f  1 1 2 6 24 120\n\nFib: n  0 1 2 3 4 5 6 7\n      f  0 1 1 2 3 5 8 13",
                        coachNote: "Names are optional vocabulary. The table is the point."
                    ),
                    SlideCard(
                        title: "Two stop rows — Fibonacci-style (n-1 and n-2)",
                        bullets: [
                            "Some recipes need TWO previous answers. You cannot start at only n=0.",
                            "Write BOTH given rows first: f(0)=0 and f(1)=1. Those are two stops, not one.",
                            "Row 2 uses both: f(1)+f(0)=1+0=1. Row 3: f(2)+f(1)=1+1=2. Always the two rows above.",
                            "If you only fill f(0) and then try f(2), you are missing a row. The recipe is illegal until f(1) exists.",
                            "Contest cousin: g(n)=g(n-1)+g(n-2)+1. Same table, extra +1 each time."
                        ],
                        diagram: "n | f(n) | how\n0 |  0   | given (stop 1)\n1 |  1   | given (stop 2)\n2 |  1   | 1+0\n3 |  2   | 1+1\n4 |  3   | 2+1\n5 |  5   | 3+2",
                        coachNote: "Cover row 1. Ask why f(2) is stuck. Uncover. Two volunteers own the two base rows."
                    ),
                    SlideCard(
                        title: "Contest shape: when x is negative — the other stopping rule",
                        bullets: [
                            "Wiki sample: g(x) = g(x-3)+1  if x>0,  else  3x. The else includes ZERO? Read: if x>0 recurse; otherwise (x≤0) use 3x. Zero: 3×0=0. Negatives: 3 times that negative.",
                            "Worked g(7): 7>0 so g(4)+1. 4>0 so g(1)+1. 1>0 so g(-2)+1. -2 is not >0, so g(-2)=3×(-2)=-6.",
                            "Now add the +1s on the way back: g(1)=-6+1=-5. g(4)=-5+1=-4. g(7)=-4+1=-3.",
                            "Three-band example: if x>5 use one formula; if 0≤x≤5 use another; if x<0 use h(x+3) — you CLIMB toward zero by adding 3, then come back.",
                            "Always write the test that fired: >0? ≤0? <0? Do not assume stopping is only n=0."
                        ],
                        diagram: "g(7)=g(4)+1\n    =g(1)+1+1\n    =g(-2)+1+1+1\n    =-6 + 3 = -3\n\nNegative x is allowed. 3x can be negative. That is the answer."
                    ),
                    SlideCard(
                        title: "Contest shape: three bands — wiki h(13)=4",
                        bullets: [
                            "Wiki: h(x)=h(x-7)+1 if x>5; h(x)=x if 0<=x<=5; h(x)=h(x+3) if x<0.",
                            "h(13): 13>5 so h(6)+1. 6>5 so h(-1)+1. -1<0 so h(2). 2 is in 0 to 5 so h(2)=2.",
                            "Back up: h(-1)=2, h(6)=3, h(13)=4.",
                            "When x is negative you ADD to climb toward the middle band. When x is large you SUBTRACT."
                        ],
                        diagram: "h(13)=h(6)+1\n     =h(-1)+1+1\n     =h(2)+1+1\n     =2+2=4",
                        coachNote: "Three volunteers: big x, middle x, negative x. Each names the band first."
                    ),
                    SlideCard(
                        title: "Contest shape: two arguments the ACSL way — f(x-y, y-1)+2",
                        bullets: [
                            "Wiki sample: f(x,y) = f(x-y, y-1)+2  if x>y,  else  x+y.",
                            "Stopping is not ‘hit zero.’ Stopping is ‘x is NOT greater than y’ — including equal.",
                            "f(5,3): 5>3 true, so f(2,2)+2. Now 2>2 false, so f(2,2)=2+2=4. Then f(5,3)=4+2=6.",
                            "Longer example f(4,1): 4>1 so f(3,0)+2. 3>0 so f(3,-1)+2. 3>-1 so f(4,-2)+2. Keep listing (x,y) until x≤y, then x+y, then +2 for every pending step.",
                            "Safer: write the chain of pairs on paper. Never jump. Stop when x is not greater than y."
                        ],
                        diagram: "f(5,3) → f(2,2)+2\n2>2? No. f(2,2)=4\nso f(5,3)=6\n\nChain: (5,3) → (2,2) STOP 4, then +2.",
                        coachNote: "Do f(5,3) as a class. Do NOT start f(6,2) until 5,3 is automatic — that one chains longer."
                    ),
                    SlideCard(
                        title: "Contest shape: wiki two-arg f(12,6)=9",
                        bullets: [
                            "Same rule: f(x,y)=f(x-y,y-1)+2 if x>y, else x+y.",
                            "f(12,6): 12>6 so f(6,5)+2. 6>5 so f(1,4)+2. 1>4 false, f(1,4)=5.",
                            "Back up: f(6,5)=7, f(12,6)=9.",
                            "Chain of pairs: (12,6) to (6,5) to (1,4) STOP 5, then +2 twice."
                        ],
                        diagram: "(12,6) -> (6,5) -> (1,4)\n1+4=5\n+2 +2 = 9",
                        coachNote: "After f(5,3)=6, this is the official wiki sample."
                    ),
                    SlideCard(
                        title: "Do now · harder recursion (4 min)",
                        bullets: [
                            "Q1. g(x)=g(x-3)+1 if x>0 else 3x. Find g(4).",
                            "Q2. Same three-band h as the wiki. Find h(6).",
                            "Q3. f(x,y)=f(x-y,y-1)+2 if x>y else x+y. Find f(5,3)."
                        ],
                        diagram: "Q1 g(4)=-4\nQ2 h(6)=3\nQ3 6",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Contest shape: paint-the-square recursion (geometry)",
                        bullets: [
                            "Wiki picture: a square of side 16. Split into 4 equal squares. Paint 1 of the 4. Recurse on the other 3. Repeat until the leftover squares have side 1.",
                            "Each level: you paint 1/4 of the current squares’ area, then three copies continue.",
                            "Side 16 → four 8×8. Paint one 8×8 (area 64). Three 8×8 remain. Each of those paints one 4×4 (area 16 × 3 = 48). Continue.",
                            "Official wiki sample: side 16 paints 175. Do not memorize 175 — a different side length is a different sum.",
                            "Work a table by stage (side 16, 8, 4, 2): how many squares painted at that size × area, then add."
                        ],
                        diagram: "Side 16: paint 1 square area 64.  3 left.\nSide  8: paint 3 squares area 16 → 48.\nSide  4: paint 9 squares area  4 → 36.\nSide  2: paint 27 squares area 1 → 27.\nTotal painted 64+48+36+27 = 175.\n(Unpainted tiny remainder is 0 at side 1 if the rule paints the last 1s — wiki total 175.)",
                        coachNote: "Draw the first split on the board. The 175 is a famous ACSL sample — if they memorize 175 without the table, they will miss a different side length."
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
                            "Also: g(7) from g(x)=g(x-3)+1 if x>0 else 3x. And f(5,3) from f(x,y)=f(x-y,y-1)+2 if x>y else x+y."
                        ],
                        diagram: "A f(4)=33\\nB g(5)=12\\nC h(6)=3\\ng(7)=-3\\nf(5,3)=6",
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
                        title: "ACSL short-answer uses pseudocode, not Python indent",
                        bullets: [
                            "Junior short-answer has 6 questions total (2 number systems, 2 recursion, 2 branching). Branching is ACSL / Pascal-like: if … then … else …, INPUT, OUTPUT. You may see THEN and END IF.",
                            "Read it as the same hallway: one condition, then-block or else-block. Trace a variable table.",
                            "input a, b  means the problem will tell you the starting numbers in the stem (‘for a=7, b=3’).",
                            "output a, b  means write those final values in that order — that is the answer.",
                            ":= or = may mean ‘put in the box’ in pseudocode. The test for equal is often = or == depending on the year. The stem’s sample is the law."
                        ],
                        diagram: "a := 7\nb := 3\nif a > b then\n    a := a - b\nelse\n    b := b - a\nendif\noutput a, b\n\nSame as Python if/else. Trace: 7>3, a=4, skip else. Output 4 3.",
                        coachNote: "Translate one ACSL block into Python on the board so they see they already know it."
                    ),
                    SlideCard(
                        title: "Contest shape: ACSL operators and built-in functions (WDTTPD)",
                        bullets: [
                            "From the ACSL ‘What Does This Program Do?’ wiki — Junior Contest 1 branching uses these, NOT loops or arrays.",
                            "Arithmetic: + − * /  (slash is real divide)  % remainder  ^ exponent  ! factorial.",
                            "Compare: == equal, != not equal, < > <= >=.",
                            "Logic: && and, || or.  ! in front of a test can mean NOT (read the stem).",
                            "Functions: abs(x) absolute value. sqrt(x) square root. int(x) is FLOOR — chop toward −∞ for positives it looks like ‘drop the decimal.’ int(3.9)=3. int(-1.2) is −2 if they use true floor; Junior samples are usually positive.",
                            "Two statements on one line: a colon :  means ‘then do this too.’ Example: a := 1 : b := 2."
                        ],
                        diagram: "5 / 2     = 2.5    (real divide)\n5 % 2     = 1      (remainder)\n5 ^ 2     = 25     (not XOR here)\n5 !       = 120    (factorial)\nint(9/2)  = 4      (floor of 4.5)\nabs(-3)   = 3",
                        coachNote: "Poster: % leftover, / real, // is Python-only. ACSL pseudocode uses / as real and int() to floor."
                    ),
                    SlideCard(
                        title: "Contest shape: INPUT, THEN, END IF, and the overtime classic",
                        bullets: [
                            "INPUT h, r  means the problem gives starting hours and rate in the question stem.",
                            "IF condition THEN  statement(s)  END IF.  ELSE sits between THEN-block and END IF.",
                            "Classic ACSL sample (overtime): two SEPARATE IFs, not if/else. Hours=50, rate=10.",
                            "IF h>48 THEN r := r+5 END IF.  Then IF h>40 THEN r := r + (h-40)*2 END IF.",
                            "50>48 true, r=15. 50>40 true, r=15+(10)*2=35. BOTH ran. If they invent an else, they get 15 and miss the point.",
                            "Junior Contest 1 must NOT use FOR, WHILE, arrays, or string loops on the paper. If you see a loop, you are in the wrong contest packet."
                        ],
                        diagram: "h := 50\nr := 10\nIF h > 48 THEN\n    r := r + 5\nEND IF\nIF h > 40 THEN\n    r := r + (h - 40) * 2\nEND IF\nOUTPUT r\n\n→ 35",
                        coachNote: "This is THE two-if trap with a story. Act it: bonus for over 48, then overtime dollars for hours past 40."
                    ),
                    SlideCard(
                        title: "Contest shape: wiki overtime payroll (answer 560)",
                        bullets: [
                            "Official WDTTPD sample is a full paycheck. Hours 50, rate 10, b starts at 0.",
                            "IF h>48 THEN b = b+(h-48)*2*r and set h=48. Double for hours past 48.",
                            "IF h>40 THEN b = b+(h-40)*(3/2)*r and set h=40. Time-and-a-half for 40-48.",
                            "Then b = b + h*r pays straight time for the remaining 40.",
                            "Trace: b=40 h=48; then b=160 h=40; then +400. Total 560.",
                            "ACSL / is real divide: 3/2=1.5. Both IFs run, and they CHANGE h for the next test."
                        ],
                        diagram: "b   h\n0   50\n40  48\n160 40\n560 40\nOUTPUT 560",
                        coachNote: "Mini +5 version first in Week 7. This 560 table in Week 8 if they are ready."
                    ),
                    SlideCard(
                        title: "Do now · two IFs and payroll (4 min)",
                        bullets: [
                            "Q1. Mini: h=50, r=10. IF h>48 THEN r:=r+5. IF h>40 THEN r:=r+(h-40)*2. Final r?",
                            "Q2. a:=4, b:=9. IF a>b THEN a:=a+1 ELSE b:=b-a. OUTPUT a,b.",
                            "Q3. Full wiki payroll (h=50, r=10). Final b?"
                        ],
                        diagram: "Q1 35\nQ2 4 5\nQ3 560",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
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
                        title: "Python: % in an if — even/odd traces",
                        bullets: [
                            "if n % 2 == 0: means ‘if n is even.’ else is the odd path.",
                            "Worked: n=5, odd, so 3*n+1=16. n=10, even, n//2=5.",
                            "Do not mix up % and //. % leftover. // how many whole groups.",
                            "On paper, write EVEN or ODD next to n before you branch."
                        ],
                        diagram: "n = 5\nif n % 2 == 0:\n    n = n // 2\nelse:\n    n = 3 * n + 1\nprint(n)        # 16\n\nn = 10\n# even path → 5",
                        coachNote: "This is the programming-problem cousin of Week 7 tracing. Pair with the Collatz-one-step lab."
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
                            "0:40–1:10  Team Mock Exams → Contest 1 Sitting A (6 short-answer: 2+2+2). Quiet. Then reveal keys. Extra sittings B–D are in the same tab.",
                            "1:10–1:25  Contest-day checklist. One combined .py: convert or recurse as assigned, print only the answer.",
                            "1:25–1:30  Light homework: sleep and a short mixed review, no new topics."
                        ],
                        diagram: "Target: mock ≥ 4/5\\nProgramming output is EXACTLY the number\\nHex strip A=10…F=15 in the pencil case",
                        coachNote: "Do not teach Contest 2 tonight. Confidence > new content."
                    ),
                    SlideCard(
                        title: "Timed mixed 6 — looks like the real short-answer (15 min)",
                        bullets: [
                            "Silent. Pencil. 15 minutes. Six questions, two per topic — that is the real Junior paper.",
                            "Q1. How many 1s in binary of 45?",
                            "Q2. Convert 2F₁₆ to octal (binary bridge).",
                            "Q3. f(0)=1, f(n)=n+f(n-1). Find f(f(3)).",
                            "Q4. g(x)=g(x-3)+1 if x>0 else 3x. Find g(7).",
                            "Q5. ACSL: a:=4, b:=9; if a>b then a:=a+1 else b:=b-a; output a,b.",
                            "Q6. Hours=50, rate=10. if h>48 then r:=r+5. if h>40 then r:=r+(h-40)*2. Final r?"
                        ],
                        diagram: "Answers (reveal after the timer):\nQ1 4\nQ2 57₈\nQ3 29\nQ4 -3\nQ5 4 5\nQ6 35  (both IFs run)",
                        coachNote: "Grade like ACSL: exact. Then walk only the misses. Team Mock Exams has Contest 1 sittings A–D (different numbers). Official ACSL also posts one Junior sample PDF per contest plus wiki samples; extra years are sold on the ACSL registration page."
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
                title: "Contest 2 — Prefix/Infix/Postfix, Bit-String Flicking, Looping",
                topics: ["Prefix / Infix / Postfix", "Bit-String Flicking", "WDTTPD Looping"],
                slides: [
                    SlideCard(
                        title: "Welcome — Contest 2 (official Junior syllabus)",
                        bullets: [
                            "Still 6 short-answer questions in 30 minutes: 2 prefix/infix/postfix, 2 bit-string flicking, 2 looping. Then one 72-hour HackerRank program.",
                            "Junior: no student beyond grade 9. Paper uses ACSL pseudocode for loops (FOR / WHILE), not only Python.",
                            "Bit-string operators are NOT, AND, OR, XOR, LSHIFT, RSHIFT, LCIRC, RCIRC. NAND/NOR are Contest 4 gates, not this paper.",
                            "Prefix/postfix have no PEMDAS and no parentheses. Infix does."
                        ],
                        diagram: "C2 paper: 2 + 2 + 2 = 6 questions, 30 min\nThen 72-hour program, 5 pts",
                        coachNote: "Write PREFIX · BITS · LOOPS on the board. Do not open Contest 3 tonight."
                    ),
                    SlideCard(
                        title: "Infix vs prefix vs postfix",
                        bullets: [
                            "Infix: operator in the middle. 3 + 4. School math. Parentheses and PEMDAS matter.",
                            "Prefix (Polish): operator BEFORE its two operands. + 3 4. Then * + 3 4 5 means (3+4)*5.",
                            "Postfix (Reverse Polish): operator AFTER. 3 4 +. Then 3 4 + 5 * is (3+4)*5.",
                            "ACSL operators: + − * / and ^ (exponent). Same three letters can appear as operands: A B +."
                        ],
                        diagram: "Infix:   (3 + 4) * 5\nPrefix:  * + 3 4 5\nPostfix: 3 4 + 5 *\n\nValue of all three: 35",
                        coachNote: "Hands: plus BETWEEN, plus BEFORE, plus AFTER. Same 3, 4, 5."
                    ),
                    SlideCard(
                        title: "Evaluate postfix — stack, pop TWO, right operand first",
                        bullets: [
                            "Scan left to right. Number → push. Operator → pop b, then pop a, compute a (op) b, push the result.",
                            "b is the right operand (popped first). a is the left. For minus, a − b not b − a.",
                            "Worked: 3 4 + 5 *. Push 3, push 4, plus → 7. Push 5, times → 35.",
                            "Classic: 5 1 2 + 4 * + 3 −  → 14."
                        ],
                        diagram: "5 1 2 + 4 * + 3 -\n[5]\n[5,1]\n[5,1,2]\n+  → [5,3]\n[5,3,4]\n*  → [5,12]\n+  → [17]\n[17,3]\n-  → [14]",
                        coachNote: "If they get −1 on a minus, they swapped a and b."
                    ),
                    SlideCard(
                        title: "Do now · postfix (2 min)",
                        bullets: [
                            "Show the stack after every token. Pop b then a.",
                            "Q1. 2 3 + 4 *",
                            "Q2. 5 1 2 + 4 * + 3 -",
                            "Q3. 9 3 - 2 *   (minus is a-b)"
                        ],
                        diagram: "Q1 20\nQ2 14\nQ3 12",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Evaluate prefix — scan from the RIGHT, same stack idea",
                        bullets: [
                            "Prefix is written operator-first, so evaluate from the right end.",
                            "* + 2 3 4 : from the right, 4 then 3 then 2 then + then *. + takes 2 and 3 → 5. * takes 5 and 4 → 20.",
                            "Or rewrite as a tree: * applies to (+ 2 3) and 4."
                        ],
                        diagram: "* + 2 3 4\n= * (2+3) 4\n= * 5 4\n= 20",
                        coachNote: "If prefix melts them, convert to infix with parentheses first, then compute."
                    ),
                    SlideCard(
                        title: "Convert infix → postfix (the contest shape)",
                        bullets: [
                            "Wiki method: fully parenthesize the infix. Each ‘term’ is (operand op operand).",
                            "Write the operands in the same left-to-right order. After each term is finished, write its operator AFTER those operands.",
                            "(3 + 4) * 5  →  3 4 + 5 *",
                            "3 + 4 * 5 with PEMDAS is 3 + (4 * 5) → 3 4 5 * +  not  3 4 + 5 *.",
                            "Check: convert your postfix back to infix. If it is not the original, you dropped parentheses."
                        ],
                        diagram: "Infix PEMDAS:  3 + 4 * 5  =  3+(4*5)\nPostfix:       3 4 5 * +\n\nInfix grouped: (3+4)*5\nPostfix:       3 4 + 5 *",
                        coachNote: "The #1 trap is ignoring PEMDAS and always doing left-to-right."
                    ),
                    SlideCard(
                        title: "Convert infix → prefix",
                        bullets: [
                            "Same parenthesize step. Write operators BEFORE their two operands.",
                            "(3+4)*5 → * + 3 4 5",
                            "3+4*5 → + 3 * 4 5",
                            "^ is exponent. Fully parenthesize (A*B)^(C/D) before moving operators."
                        ],
                        diagram: "(3 + 4) * 5\nprefix: * + 3 4 5\n\n3 + 4 * 5\nprefix: + 3 * 4 5",
                        coachNote: "Do one conversion on the board with nested parentheses drawn huge."
                    ),
                    SlideCard(
                        title: "Do now · convert notation (3 min)",
                        bullets: [
                            "Parenthesize first. PEMDAS on infix.",
                            "Q1. (3+4)*5 as postfix AND prefix.",
                            "Q2. 3+4*5 as postfix. (Not the same as Q1.)",
                            "Q3. Prefix * + 2 3 4. Value?"
                        ],
                        diagram: "Q1  3 4 + 5 *    and    * + 3 4 5\nQ2  3 4 5 * +\nQ3  20",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Bit-string flicking — NOT AND OR XOR (not NAND)",
                        bullets: [
                            "A bit-string is only 0s and 1s. Same length after padding.",
                            "NOT (~) flips each bit. 1010 → 0101. Width stays the same. Leading 0s count.",
                            "AND: 1 only if both 1. OR: 1 if at least one 1. XOR: 1 if the bits DIFFER.",
                            "If one string is shorter, pad 0s on the LEFT until they match. 11010 AND 1110 → 11010 AND 01110 = 01010."
                        ],
                        diagram: "1011 AND 1101 = 1001\n1011 OR  1101 = 1111\n1011 XOR 1101 = 0110\nNOT 1010     = 0101\n\nPad left: 1110 → 01110 if the other is 5 bits",
                        coachNote: "NAND/NOR wait for Contest 4 circuits. Do not mix them into bit-string homework."
                    ),
                    SlideCard(
                        title: "LSHIFT / RSHIFT vs LCIRC / RCIRC",
                        bullets: [
                            "LSHIFT-x: move left x places. Bits that fall off the left are GONE. Zeros enter on the right. Width unchanged.",
                            "RSHIFT-x: move right x places. Zeros enter on the left.",
                            "LCIRC-x: rotate left. Bits that fall off the left come back on the right.",
                            "RCIRC-x: rotate right. Bits that fall off the right come back on the left.",
                            "Wiki: LSHIFT-2 of 01101 = 10100. RCIRC-1 of 01101 = 10110. LCIRC-3 of 01101 = 01011."
                        ],
                        diagram: "x = 01101\nLSHIFT-2  10100   (lost two left bits, zeros in)\nRSHIFT-3  00001\nLCIRC-3   01011   (01101 → 01011)\nRCIRC-1   10110",
                        coachNote: "Fingers on paper: SHIFT loses, CIRC keeps. Chant it."
                    ),
                    SlideCard(
                        title: "Bit-string order of operations (memorize)",
                        bullets: [
                            "Highest to lowest: NOT, then SHIFT and CIRC, then AND, then XOR, then OR.",
                            "Equal-level binary ops go left to right. Unary NOT binds right to left.",
                            "Parentheses still win. Work inside-out on nested CIRC.",
                            "Wiki: (RSHIFT-1 (LCIRC-4 (RCIRC-2 01101))) → RCIRC-2 = 01011, LCIRC-4 = 10101, RSHIFT-1 = 01010."
                        ],
                        diagram: "Precedence (high → low):\n  NOT\n  LSHIFT RSHIFT LCIRC RCIRC\n  AND\n  XOR\n  OR\n\n(RSHIFT-1 (LCIRC-4 (RCIRC-2 01101))) = 01010",
                        coachNote: "Wrong order AND vs OR is a free missed point. Poster this list."
                    ),
                    SlideCard(
                        title: "Do now · bits (3 min)",
                        bullets: [
                            "Pad shorter on the LEFT. CIRC keeps bits; SHIFT loses them.",
                            "Q1. 1011 AND 1101",
                            "Q2. RCIRC-1 of 01101",
                            "Q3. (RSHIFT-1 (LCIRC-4 (RCIRC-2 01101)))"
                        ],
                        diagram: "Q1 1001\nQ2 10110\nQ3 01010",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "ACSL looping — FOR start TO end STEP",
                        bullets: [
                            "Junior Contest 2 paper uses ACSL FOR, not Python range, unless the stem is Python.",
                            "FOR i = start TO end STEP inc ... NEXT i. i runs start, start+inc, … while it has not passed end.",
                            "If STEP is missing, STEP is +1. STEP −1 counts down. NEXT i is the bottom of the loop.",
                            "FOR i = 1 TO 4 : s = s + i  NEXT i  with s=0 → 10. That is 1,2,3,4 — end is INCLUDED.",
                            "Python range(1,4) is 1,2,3 only. That trap is for the programming problem, not the ACSL FOR paper."
                        ],
                        diagram: "s = 0\nFOR i = 1 TO 4 STEP 1\n    s = s + i\nNEXT i\nOUTPUT s\n\n→ 10   (1+2+3+4)\n\nPython: range(1,4) would be 6. Different."
                    ),
                    SlideCard(
                        title: "ACSL WHILE — test at the top, table every pass",
                        bullets: [
                            "WHILE condition ... END WHILE. If the test is false at the top, the body never runs.",
                            "If the body never changes the test, it is an infinite loop — ACSL will not do that on Junior.",
                            "Columns: pass number, variables, whether the WHILE test is true.",
                            "Nested: inner WHILE/FOR finishes completely for each outer pass."
                        ],
                        diagram: "n = 1 : s = 0\nWHILE n < 5\n    s = s + n\n    n = n + 1\nEND WHILE\nOUTPUT s\n\nn: 1,2,3,4 then 5 stops. s=10.",
                        coachNote: "Cover the body when the test is false. Same physical trick as else."
                    ),
                    SlideCard(
                        title: "Do now · ACSL loops (3 min)",
                        bullets: [
                            "FOR end is INCLUDED. Python range is not this paper.",
                            "Q1. s=0. FOR i=1 TO 4 STEP 1. s=s+i. NEXT i. Output s.",
                            "Q2. Python: s=0; for i in range(1,4): s+=i. Final s?",
                            "Q3. n=1,s=0. WHILE n<4: s=s+n; n=n+1. Output s."
                        ],
                        diagram: "Q1 10\nQ2 6\nQ3 6",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Python lab — postfix evaluator (HackerRank shape)",
                        bullets: [
                            "Programming is still 72 hours, exact print. Contest 2 often looks like evaluate an expression or simulate a loop.",
                            "split() tokens. Integers vs operators. Pop b then a.",
                            "Include ^ as ** if the spec uses exponent."
                        ],
                        diagram: "tokens = input().split()\nstack = []\nfor tok in tokens:\n    if tok in '+-*':\n        b = stack.pop(); a = stack.pop()\n        # compute a (op) b, then append\n    else:\n        stack.append(int(tok))\nprint(stack[-1])",
                        coachNote: "Type 3 4 + 5 * and wait for 35 before leaving lab."
                    ),
                    SlideCard(
                        title: "Timed mixed 6 · Contest 2 (12 min)",
                        bullets: [
                            "Silent. Two notation, two bits, two loops. Then grade.",
                            "Q1. Postfix 3 4 + 5 *",
                            "Q2. Infix (3+4)*5 as postfix",
                            "Q3. 1011 XOR 1101",
                            "Q4. LSHIFT-1 of 1011 (4 bits, 0-fill)",
                            "Q5. FOR i=1 TO 3: s=s+i with s=0. Output s.",
                            "Q6. WHILE n<3 starting n=1 s=0: s=s+n; n=n+1. Output s."
                        ],
                        diagram: "Q1 35\nQ2 3 4 + 5 *\nQ3 0110\nQ4 0110\nQ5 6\nQ6 3",
                        coachNote: "Then open Team Mock Exams Contest 2 for a second 6."
                    )
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
                    "Postfix: pop b then a. a - b not b - a.",
                    "ACSL FOR includes the end value. Python range does not.",
                    "Bit-strings: pad the shorter on the LEFT. CIRC keeps bits; SHIFT loses them.",
                    "72-hour program: print only the number."
                ],
                homework: """
                # Contest 2 homework
                # Paper: infix (3+4)*5 → postfix and prefix.
                # Paper: RCIRC-1 of 01101. Precedence poster.
                # Paper: ACSL FOR i=1 TO 4, s+=i → 10.
                # Code: postfix 5 1 2 + 4 * + 3 -  → 14

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
                title: "Contest 3 — Boolean Algebra, Data Structures, Arrays",
                topics: ["Boolean Algebra", "Stacks / Queues", "WDTTPD Arrays"],
                slides: [
                    SlideCard(
                        title: "Welcome — Contest 3 (official Junior syllabus)",
                        bullets: [
                            "6 questions, 30 minutes: 2 Boolean algebra, 2 stacks/queues, 2 array tracing (ACSL A(i) style).",
                            "Then 72-hour programming. Arrays on the PAPER are ACSL arrays, not always Python lists.",
                            "Junior data structures: stack PUSH/POP and queue enqueue/dequeue. Not trees."
                        ],
                        diagram: "C3: Boolean · Stack/Queue · Arrays\n6 Q, 2 each, 30 min + 72-hr program",
                        coachNote: "Do not teach FSAs or LISP — those are other divisions."
                    ),
                    SlideCard(
                        title: "Boolean algebra — symbols and identities",
                        bullets: [
                            "AND is · or just write AB. OR is +. NOT is A' or Ā or NOT A.",
                            "A+0=A, A·1=A, A+1=1, A·0=0, A+A=A, A·A=A.",
                            "A+A'=1, A·A'=0.  (A')'=A.",
                            "XOR is 1 iff the two bits differ. XNOR is 1 iff they match.",
                            "Order unless parentheses: NOT, then AND, then OR."
                        ],
                        diagram: "A + 0 = A     A · 1 = A\nA + A' = 1    A · A' = 0\nA + 1 = 1     A · 0 = 0",
                        coachNote: "Quiz identities with the hex-strip energy. Speed matters."
                    ),
                    SlideCard(
                        title: "DeMorgan — both directions, then stop expanding",
                        bullets: [
                            "(A+B)' = A' · B'.  (A·B)' = A' + B'.",
                            "ACSL often wants the simplified form, not a 16-row expansion.",
                            "Distribute only if simplify-first did not finish. A(B+C)=AB+AC.",
                            "Worked: (A+B)' + C  is not the same as A'+B'+C without care — DeMorgan applies to the grouped NOT."
                        ],
                        diagram: "(A + B)' = A' · B'\n(A · B)' = A' + B'\n\nSimplify (A+0)' · 1 = A'",
                        coachNote: "Write both DeMorgan laws as a poster. Point at the dual every time."
                    ),
                    SlideCard(
                        title: "Do now · Boolean (2 min)",
                        bullets: [
                            "Q1. (A+B)'",
                            "Q2. (A·B)'",
                            "Q3. A + A' · 1  (AND before OR)"
                        ],
                        diagram: "Q1 A'B'\nQ2 A'+B'\nQ3 1",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Stack — LIFO, ACSL PUSH / POP",
                        bullets: [
                            "Stack: last in, first out. PUSH adds on top. POP removes the top.",
                            "Trace a column ‘top → bottom’. After PUSH A, PUSH B, POP, PUSH C: top is C, then A.",
                            "POP on empty: Junior stems usually avoid it; programming code should still guard.",
                            "Answer format: remaining items top-first or left-to-right as the sample shows."
                        ],
                        diagram: "PUSH A     [A]\nPUSH B     [A, B]  top=B\nPOP        [A]\nPUSH C     [A, C]  top=C\n\nTop to bottom: C, A",
                        coachNote: "Use a stack of real paper plates."
                    ),
                    SlideCard(
                        title: "Queue — FIFO, enqueue back, dequeue front",
                        bullets: [
                            "Queue: first in, first out. ENQ / enqueue at the BACK. DEQ / dequeue from the FRONT.",
                            "ENQ X, ENQ Y, DEQ → Y is now at the front.",
                            "Do not mix stack POP with queue DEQ in the same mental picture — draw two boxes."
                        ],
                        diagram: "ENQ X   front → X\nENQ Y   front → X Y\nDEQ     front → Y\n\nFront item: Y",
                        coachNote: "Cafeteria line. First tray in is first tray out."
                    ),
                    SlideCard(
                        title: "Do now · stack and queue (2 min)",
                        bullets: [
                            "Q1. PUSH A, PUSH B, POP, PUSH C. Top to bottom (top first).",
                            "Q2. ENQ X, ENQ Y, DEQ. Front item?",
                            "Q3. Start empty. PUSH A, ENQ B, POP, DEQ. Stack leftover? Queue leftover?"
                        ],
                        diagram: "Q1 C, A\nQ2 Y\nQ3 both empty",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "ACSL arrays — A(1) vs A(0), 2-D is (row, col)",
                        bullets: [
                            "Paper arrays look like A(5) = 9. The stem says whether indexing starts at 0 or 1. Wiki: most past problems start at A(1) or A(1,1).",
                            "1-D: one subscript. 2-D: A(row, col). Not (col, row).",
                            "Assignment A(2) = A(1) + A(3) mutates in place. Later lines see the new value.",
                            "Python lists are 0-based and use a[2]. Translate carefully. a[1:4] excludes 4 — that is Python, not ACSL A(1) to A(4)."
                        ],
                        diagram: "Start (1-based): A(1)=2, A(2)=4, A(3)=6\nA(2) = A(1) + A(3)\nNow A(2)=8. List: 2, 8, 6\n\n2-D: A(2,3) is row 2, column 3.",
                        coachNote: "Circle the first index in the stem before tracing."
                    ),
                    SlideCard(
                        title: "Array + WHILE — write a table of j, k, n, A(j)",
                        bullets: [
                            "Contest 3 looping is allowed because the topic is arrays — WHILE walking A(k) until A(k)<0 is on-syllabus here.",
                            "Wiki merge sample is long. Method: one row per inner-loop pass. Ask for one cell, like C(4), not the whole array.",
                            "Never update an index in your head. If j and k both move, both columns."
                        ],
                        diagram: "A(0)=12 A(1)=41 A(2)=52 A(3)=57 A(4)=77 A(5)=-100\nWiki merge with B: C(4) ends as 52.\nYou do not need to memorize 52 — you need the table habit.",
                        coachNote: "If they refuse to make a table, stop and make them. The point is the table."
                    ),
                    SlideCard(
                        title: "Do now · ACSL arrays (3 min)",
                        bullets: [
                            "Assume 1-based unless the stem says 0.",
                            "Q1. A(1)=2, A(2)=4, A(3)=6. A(2)=A(1)+A(3). A(2)?",
                            "Q2. Same start. Then A(3)=A(2)+1. A(3)? Uses the NEW A(2).",
                            "Q3. A(1,2) means which cell?"
                        ],
                        diagram: "Q1 8\nQ2 9\nQ3 row 1, column 2",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Python lab — stack and queue commands",
                        bullets: [
                            "list.append / list.pop() is a stack. collections.deque append / popleft is a queue.",
                            "Print remaining items as the spec says: spaces, no brackets.",
                            "72-hour window. Guard extra POP."
                        ],
                        diagram: "PUSH A\nPUSH B\nPOP\nENQ C\nDEQ\n\n# implement, print leftover exactly",
                        coachNote: "One mixed script, then one array-mutate script. Two files."
                    ),
                    SlideCard(
                        title: "Timed mixed 6 · Contest 3 (12 min)",
                        bullets: [
                            "Q1. (A+B)'",
                            "Q2. A=1, B=0. XOR?",
                            "Q3. PUSH A, PUSH B, POP, PUSH C. Top first.",
                            "Q4. ENQ X, ENQ Y, DEQ. Front?",
                            "Q5. A(1)=2,A(2)=4,A(3)=6; A(2)=A(1)+A(3). A(2)?",
                            "Q6. A(2,1) is row ____ column ____."
                        ],
                        diagram: "Q1 A'B'\nQ2 1\nQ3 C,A\nQ4 Y\nQ5 8\nQ6 row 2, column 1",
                        coachNote: "Second set: Team Mock Exams Contest 3."
                    )
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
                    "Return a string, not a list object.",
                    "ACSL A(1) is not Python a[1] unless the stem starts at 0.",
                    "DeMorgan both laws before expanding."
                ],
                homework: """
                # Contest 3 homework
                # Paper: (A+B)' and (AB)'. Stack PUSH A B POP PUSH C.
                # Paper: 1-based A(1)=2 A(2)=4 A(3)=6; A(2)=A(1)+A(3).
                # Code: simulate PUSH/POP/ENQ/DEQ.

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
                title: "Contest 4 — Graph Theory, Digital Electronics, Strings",
                topics: ["Graph Theory", "Digital Electronics", "WDTTPD Strings"],
                slides: [
                    SlideCard(
                        title: "Welcome — Contest 4 (official Junior syllabus)",
                        bullets: [
                            "6 questions, 30 minutes: 2 graph theory, 2 digital electronics (gates), 2 string tracing.",
                            "Bit shifts/CIRC are Contest 2 bit-string flicking. They are NOT a Contest 4 short-answer topic.",
                            "Strings: ACSL pseudocode, 0-based index, len, slices, concatenate with +.",
                            "Still one 72-hour HackerRank program after the paper."
                        ],
                        diagram: "C4: Graphs · Circuits · Strings\nNOT bit-shifts on this paper",
                        coachNote: "If last year’s notes say ‘bit shifts for C4’, throw that page away."
                    ),
                    SlideCard(
                        title: "Graphs — vertices, edges, directed vs undirected",
                        bullets: [
                            "A graph is a set of vertices (points) and edges (connections). The drawing can move; the edge list is the graph.",
                            "Undirected: AB is the same as BA. Directed: arrow AB is not BA unless both arrows exist.",
                            "Path: a walk on edges. Simple path: no repeated vertex. Cycle: simple except start=end (HEGH).",
                            "Connected: you can reach every vertex from every other (undirected sense). Otherwise: connected components."
                        ],
                        diagram: "V = {A,B,C}   E = {AB, BC}\nPath A-B-C. No cycle.\nAdd CA → cycle ABCA.\n\nDirected AB only: A can reach B, B cannot reach A.",
                        coachNote: "Build the graph with sticky notes before any matrix."
                    ),
                    SlideCard(
                        title: "Trees, forests, counting cycles",
                        bullets: [
                            "Tree: connected, no cycles. A tree with N vertices has exactly N−1 edges.",
                            "Forest: several trees (disconnected, still no cycles).",
                            "Wiki sample: vertices A–E, edges AB,BA,BC,CD,DC,DB,DE. Cycles ABA, BCDB, CDC. Answer 3.",
                            "List cycles by the vertex sequence. Same loop written rotated is the same cycle — do not double-count."
                        ],
                        diagram: "Tree: 4 vertices, 3 edges. No loop.\n\nWiki cycles: ABA, BCDB, CDC → 3",
                        coachNote: "Count cycles by walking; then check you did not list the same loop twice."
                    ),
                    SlideCard(
                        title: "Adjacency matrix and walks of length p",
                        bullets: [
                            "N vertices → N×N grid. Cell (i,j) is 1 if there is an edge i→j (directed). 0 otherwise.",
                            "Undirected: the matrix is symmetric. Degree of i = sum of row i (undirected, no loops).",
                            "M²[i,j] = number of walks of length 2 from i to j. M^p counts walks of length p.",
                            "Contest asks ‘how many paths of length 2 or 4 from A to C?’ Add the two cells from M² and M⁴ if they want both lengths."
                        ],
                        diagram: "A—B—C undirected\n   A B C\nA  0 1 0\nB  1 0 1\nC  0 1 0\n\n(A²)[A,C] = 1  (walk A-B-C)",
                        coachNote: "Compute A² by hand for 3×3 before any Python."
                    ),
                    SlideCard(
                        title: "Do now · graphs (3 min)",
                        bullets: [
                            "Q1. Undirected A-B-C. Walks of length 2 from A to C?",
                            "Q2. Same graph: adjacency A[A,C] (direct edge)?",
                            "Q3. A tree with 5 vertices has how many edges?"
                        ],
                        diagram: "Q1 1\nQ2 0\nQ3 4",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Digital electronics — the eight Junior gates",
                        bullets: [
                            "BUFFER: output = input. NOT: flip. AND: both 1. OR: at least one 1.",
                            "NAND: AND then NOT. NOR: OR then NOT. XOR: differ. XNOR: same (match).",
                            "NAND/NOR belong here, not on the Contest 2 bit-string paper.",
                            "Translate the drawing to a Boolean expression, then a truth table, then count rows that are TRUE or FALSE as asked."
                        ],
                        diagram: "AND  1 only if both 1\nOR   1 if at least one 1\nXOR  1 iff they differ\nNAND 0 only if both 1\nNOR  1 only if both 0\nXNOR 1 iff they match",
                        coachNote: "Flash each gate with two fingers until NAND vs NOR is automatic."
                    ),
                    SlideCard(
                        title: "Contest shape: which inputs make the circuit FALSE / how many tuples",
                        bullets: [
                            "Wiki: circuit FALSE only when both inputs to a final OR are false — chase backwards.",
                            "Example: F = (A AND B)' + C is FALSE only for (A,B,C)=(1,1,0).",
                            "‘How many ordered 4-tuples make F TRUE?’ → 16-row truth table, count 1s in the output column.",
                            "Simplify with DeMorgan when the circuit is messy: (AB)'+C FALSE ⇔ AB C'  TRUE."
                        ],
                        diagram: "F = NOT(A AND B) OR C\nF is FALSE only if NOT(AB)=0 and C=0\nNOT(AB)=0 means AB=1, so A=1, B=1, C=0\nOne ordered triple: (1,1,0)",
                        coachNote: "Small circuits: chase. Four inputs: truth table. Do not guess."
                    ),
                    SlideCard(
                        title: "Do now · gates (3 min)",
                        bullets: [
                            "Q1. NAND of 1 and 1.",
                            "Q2. F = NOT(A AND B) OR C. Ordered triple that makes F FALSE?",
                            "Q3. XOR of 1 and 0."
                        ],
                        diagram: "Q1 0\nQ2 1,1,0\nQ3 1",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "ACSL strings — index 0, len, concatenate +",
                        bullets: [
                            "Strings sit in double quotes. len(S) is the number of characters. Empty string has length 0.",
                            "First character is S[0]. Last is S[len(S)-1]. S[len(S)] is an error.",
                            "Concatenate: t = t + a[j] glues characters. Used to reverse: loop j from len-1 down to 0.",
                            "Wiki BANANAS: reverse into t, then count positions where a[j]==t[j]. Answer 5 (the middle palindrome run)."
                        ],
                        diagram: "a = \"BANANAS\"   len=7\nreverse t = \"SANANAB\"\nmatch at j=1,2,3,4,5  → 5\n(not 7, not 6)",
                        coachNote: "Write index numbers under every letter before looping."
                    ),
                    SlideCard(
                        title: "ACSL slices vs Python slices (read the sample)",
                        bullets: [
                            "Wiki: S = \"ACSL WDTPD\" length 10. S[:3] = first 3 characters = ACS (like Python).",
                            "Wiki: S[2:6] = characters from index 2 THROUGH 6 INCLUSIVE = \"SL WD\". Python S[2:6] would STOP BEFORE 6.",
                            "On contest day: copy the problem’s own slice examples. If none, ACSL wiki inclusive-end is the paper habit; Python exclusive-end is the HackerRank habit.",
                            "S[0] is one character. Errors: negative index or index ≥ len."
                        ],
                        diagram: "S = ACSL WDTPD\n idx 0123456789\nS[:3]    ACS          (first 3)\nS[2:6]   SL WD        (2..6 inclusive on paper)\nPython S[2:6] would be SL W  (2,3,4,5 only)",
                        coachNote: "Box ‘inclusive end on paper / exclusive end in Python’ on the contest card."
                    ),
                    SlideCard(
                        title: "Do now · strings (3 min)",
                        bullets: [
                            "S = ACSL WDTPD (space in the middle). Index from 0.",
                            "Q1. ACSL paper S[2:6] inclusive.",
                            "Q2. Python S[2:6] exclusive — different?",
                            "Q3. BANANAS vs its reverse. Matching positions?"
                        ],
                        diagram: "Q1 SL WD\nQ2 SL W\nQ3 5",
                        coachNote: "Cover the gray box. Hands down. Then reveal."
                    ),
                    SlideCard(
                        title: "Python lab — walks of length 2, plus a string reverse count",
                        bullets: [
                            "Programming may be graphs or strings. Read the spec. Flattened token scan for matrices.",
                            "String problems: s[::-1] reverses in Python; still trace on paper the way ACSL does.",
                            "Print one integer or one string as specified. No labels."
                        ],
                        diagram: "n then n*n matrix then u v → walks length 2\n\n# or: read a string, print match-count with reverse",
                        coachNote: "One matrix program and one string program this meeting."
                    ),
                    SlideCard(
                        title: "Timed mixed 6 · Contest 4 (12 min)",
                        bullets: [
                            "Q1. Walks of length 2, A to C, on undirected A-B-C.",
                            "Q2. Cycles in AB,BA,BC,CD,DC,DB,DE (directed).",
                            "Q3. NAND 1,1",
                            "Q4. F=NOT(AB) OR C FALSE at?",
                            "Q5. ACSL S[2:6] on ACSL WDTPD",
                            "Q6. BANANAS reverse-match count"
                        ],
                        diagram: "Q1 1\nQ2 3\nQ3 0\nQ4 1,1,0\nQ5 SL WD\nQ6 5",
                        coachNote: "Then Team Mock Exams Contest 4."
                    )
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

                def palindrome_match_count(s: str) -> int:
                    t = s[::-1]
                    return sum(1 for i in range(len(s)) if s[i] == t[i])

                def solve():
                    tokens = sys.stdin.read().strip().split()
                    if len(tokens) == 1:
                        return palindrome_match_count(tokens[0])
                    it = iter(tokens)
                    n = int(next(it))
                    matrix = [[int(next(it)) for _ in range(n)] for _ in range(n)]
                    u, v = int(next(it)), int(next(it))
                    return walks_length_2(matrix, u, v)

                if __name__ == "__main__":
                    print(solve())
                """,
                pythonNotes: [
                    "Paper strings: inclusive end on ACSL [a:b]. Python slices exclude the end.",
                    "M^p[i,j] = walks of length p. A[i][j] is only length 1.",
                    "Circuit questions: count tuples or name the one FALSE row.",
                    "Vertices 0-based vs 1-based: read the stem."
                ],
                homework: """
                # Contest 4 homework
                # Paper: 3 cycles wiki; (A^2)[A,C] on A-B-C path.
                # Paper: F=(AB)'+C FALSE at (1,1,0). BANANAS match count 5.
                # Paper: S[2:6] inclusive on ACSL WDTPD.
                # Code: walks of length 2.

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
                Text(slide.diagram.replacingOccurrences(of: "\\n", with: "\n"))
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
        let width = max(max(bitsA.count, bitsB.count), 1)
        return VStack(alignment: .leading, spacing: 4) {
            Text("AND  \(formatBits(a & b, width: width))")
            Text("OR   \(formatBits(a | b, width: width))")
            Text("XOR  \(formatBits(a ^ b, width: width))")
            Text("NOT A \(formatBits(~a & mask(width), width: width))")
            Text("LSHIFT A \(formatBits((a << 1) & mask(width), width: width))")
            Text("RSHIFT A \(formatBits(a >> 1, width: width))")
            Text("LCIRC  A \(formatBits(circLeft(a, width), width: width))")
            Text("RCIRC  A \(formatBits(circRight(a, width), width: width))")
        }
    }

    private func circLeft(_ n: Int, _ w: Int) -> Int {
        let w = max(w, 1)
        let m = mask(w)
        let v = n & m
        return ((v << 1) | (v >> (w - 1))) & m
    }

    private func circRight(_ n: Int, _ w: Int) -> Int {
        let w = max(w, 1)
        let m = mask(w)
        let v = n & m
        return ((v >> 1) | ((v & 1) << (w - 1))) & m
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
                GridRow { Text("XNOR"); Text("\(av == bv ? 1 : 0)") }
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
    @State private var sample = "ACSL WDTPD"
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
            Text("ACSL strings (paper slice is inclusive)")
                .font(.headline)
            TextField("S", text: $sample)
            Text(stringTrace(sample))
                .font(.system(size: 13 * scale, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func walks(from u: Int, to v: Int) -> Int {
        (0..<4).reduce(0) { $0 + matrix[u][$1] * matrix[$1][v] }
    }

    private func stringTrace(_ s: String) -> String {
        let chars = Array(s)
        let n = chars.count
        func acslSlice(_ a: Int, _ b: Int) -> String {
            guard n > 0 else { return "" }
            let lo = max(0, a)
            let hi = min(n - 1, b)
            if lo > hi { return "" }
            return String(chars[lo...hi])
        }
        let py26 = n >= 2 ? String(chars[2..<min(6, n)]) : ""
        let rev = String(chars.reversed())
        var matches = 0
        for i in 0..<n where i < rev.count {
            if chars[i] == Array(rev)[i] { matches += 1 }
        }
        return """
        len=\(n)
        ACSL S[2:6] inclusive: \(acslSlice(2, 6))
        Python S[2:6] exclusive: \(py26)
        reverse match count: \(matches)
        """
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
    @State private var sittingPick = 0
    @State private var responses: [String] = Array(repeating: "", count: 6)
    @Environment(\.teachingScale) private var scale

    private var sittings: [MockExam] {
        Self.exams.filter { $0.contest == contestPick }
    }

    private var exam: MockExam {
        let list = sittings
        guard !list.isEmpty else {
            return MockExam(contest: contestPick, title: "Empty", questions: [])
        }
        return list[min(sittingPick, list.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Team mock · \(exam.title)")
                    .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                Text("Focus student: \(selectedStudentName). Junior paper is 6 questions (2 per topic). Official ACSL sample contests: acsl.org/get-started/study-materials.")
                    .font(.system(size: 13 * scale))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Round", selection: $contestPick) {
                    ForEach(1...4, id: \.self) { Text("Contest \($0)").tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 480)
                if sittings.count > 1 {
                    Picker("Sitting", selection: $sittingPick) {
                        ForEach(0..<sittings.count, id: \.self) { idx in
                            Text(sittingLabel(sittings[idx].title, index: idx)).tag(idx)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 480)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: contestPick) { _, _ in
                sittingPick = 0
                responses = Array(repeating: "", count: 6)
            }
            .onChange(of: sittingPick) { _, _ in
                responses = Array(repeating: "", count: 6)
            }

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
                Text("Short-answer score preview: \(score(exam))/\(max(exam.questions.count, 1))")
                    .font(.headline.monospaced())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(exam.questions.enumerated()), id: \.offset) { idx, q in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Q\(idx + 1). \(q.prompt)")
                                .font(.system(size: 15 * scale, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if idx < responses.count {
                                TextField("Answer", text: $responses[idx])
                                    .textFieldStyle(.roundedBorder)
                            }
                            if revealKeys {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Key: \(q.answer)")
                                        .font(.system(size: 16 * scale, weight: .bold, design: .monospaced))
                                    Text("Step-by-step")
                                        .font(.system(size: 12 * scale, weight: .semibold))
                                        .foregroundStyle(.orange)
                                    Text(q.derivation)
                                        .font(.system(size: 13 * scale))
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func score(_ exam: MockExam) -> Int {
        zip(responses, exam.questions).reduce(0) { acc, pair in
            acc + (normalize(pair.0) == normalize(pair.1.answer) ? 1 : 0)
        }
    }

    private func sittingLabel(_ title: String, index: Int) -> String {
        if let range = title.range(of: "Sitting ") {
            return String(title[range.lowerBound...])
        }
        return "Sitting \(Character(UnicodeScalar(65 + index)!))"
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private static let exams: [MockExam] = [
        MockExam(contest: 1, title: "Contest 1 · Sitting A", questions: [
            MockQuestion(prompt: "How many 1s in the binary of 45?", answer: "4",
                         derivation: """
                            1. Write place values from the right: 1, 2, 4, 8, 16, 32, 64, …
                            2. Make 45 with those: 32+8+4+1 = 45. So bits: 32 yes, 16 no, 8 yes, 4 yes, 2 no, 1 yes.
                            3. Binary: 101101.
                            4. Count the 1s only: four 1s. The answer is 4, not 45, and not 6 (that is how many bits).
                            """),
            MockQuestion(prompt: "Convert 2F16 to octal (binary bridge).", answer: "57",
                         derivation: """
                            1. Each hex digit → 4 bits. 2 = 0010. F = 15 = 1111.
                            2. Glue: 00101111.
                            3. Octal wants groups of 3 from the RIGHT. 8 bits is not a multiple of 3, so pad a 0 on the LEFT: 000101111.
                            4. Groups: 000 101 111 → 0 5 7. Drop the leading 0 → 57₈.
                            5. Check in decimal: 2F₁₆ = 32+15 = 47. 5×8+7 = 47. Same number. Answer 57.
                            """),
            MockQuestion(prompt: "f(0)=1, f(n)=n+f(n-1). Find f(f(3)).", answer: "29",
                         derivation: """
                            1. Inside first: f(f(3)) means compute f(3), then plug that number into f.
                            2. Table from the stop. f(0)=1 given.
                               f(1)=1+f(0)=1+1=2
                               f(2)=2+f(1)=2+2=4
                               f(3)=3+f(2)=3+4=7
                            3. So f(3)=7. Now we need f(7). Keep the table going:
                               f(4)=4+7=11
                               f(5)=5+11=16
                               f(6)=6+16=22
                               f(7)=7+22=29
                            4. Box 29. Trap: answering 7 (stopped at the inside). Trap: multiplying (factorial).
                            """),
            MockQuestion(prompt: "g(x)=g(x-3)+1 if x>0 else 3x. Find g(7).", answer: "-3",
                         derivation: """
                            1. Stop rule first: if x is NOT > 0 (zero or negative), g(x)=3x. No more calls.
                            2. 7>0, so g(7)=g(4)+1.
                            3. 4>0, so g(4)=g(1)+1.
                            4. 1>0, so g(1)=g(-2)+1.
                            5. -2 is not >0, so g(-2)=3×(-2)=-6. Stop.
                            6. Walk back, one +1 per step: g(1)=-6+1=-5. g(4)=-5+1=-4. g(7)=-4+1=-3.
                            7. Three +1s on -6 is -3. Answer -3 (negative is allowed).
                            """),
            MockQuestion(prompt: "f(x,y)=f(x-y,y-1)+2 if x>y else x+y. Find f(5,3).", answer: "6",
                         derivation: """
                            1. Stop when x is NOT greater than y (including equal): then answer is x+y.
                            2. Pair (5,3): 5>3 true → f(5-3, 3-1)+2 = f(2,2)+2.
                            3. Pair (2,2): 2>2 false → f(2,2)=2+2=4. Stop.
                            4. One pending +2: f(5,3)=4+2=6.
                            5. Write the chain of pairs: (5,3) → (2,2) STOP 4, then +2.
                            """),
            MockQuestion(prompt: "h=50, r=10. if h>48 then r:=r+5. if h>40 then r:=r+(h-40)*2. Final r?", answer: "35",
                         derivation: """
                            1. Two SEPARATE ifs. There is no else. Each test uses current values. h never changes (50 the whole time).
                            2. First: 50>48? Yes. r := 10+5 = 15.
                            3. Second: 50>40? Yes (still). Extra hours = 50-40=10. r := 15 + 10×2 = 15+20=35.
                            4. Trap: thinking else so only one if runs → 15. Trap: using original r=10 on the second if → 10+20=30. Both wrong. Final r=35.
                            """)
        ]),
        MockExam(contest: 1, title: "Contest 1 · Sitting B", questions: [
            MockQuestion(prompt: "Convert 110101₂ to decimal.", answer: "53",
                         derivation: """
                            1. Label bits from the RIGHT: 1×1 + 0×2 + 1×4 + 0×8 + 1×16 + 1×32.
                            2. Add the ON bits: 1+4+16+32.
                            3. 1+4=5, 5+16=21, 21+32=53.
                            4. Check: 32+16+4+1=53. Answer 53, not 110101, not ‘how many 1s’ (that is 4).
                            """),
            MockQuestion(prompt: "Convert 53₈ to hexadecimal (binary bridge).", answer: "2B",
                         derivation: """
                            1. Each octal digit is 3 bits. 5=101, 3=011.
                            2. Glue: 101011.
                            3. Hex wants groups of 4 from the RIGHT. 101011 is 6 bits; pad LEFT with 00: 0010 1011.
                            4. 0010=2, 1011=8+2+1=11=B. So 2B₁₆.
                            5. Check: 53₈=5×8+3=43 decimal. 2B₁₆=2×16+11=43. Matches.
                            """),
            MockQuestion(prompt: "f(0)=2, f(n)=n×f(n-1)+1. Find f(3).", answer: "22",
                         derivation: """
                            1. Stop: f(0)=2. Each next row: multiply by n, then add 1.
                            2. f(1)=1×2+1=3
                            3. f(2)=2×3+1=7
                            4. f(3)=3×7+1=22  ← they asked f(3), box 22.
                            5. f(4)=4×22+1=89. If you boxed 89 you went one row too far.
                            """),
            MockQuestion(prompt: "f(0)=0. Even n: f(n)=f(n-1)+n. Odd n: f(n)=f(n-1)-1. Find f(4).", answer: "4",
                         derivation: """
                            1. Write a middle column EVEN/ODD for every n. New n, new test.
                            2. n=0 stop: 0
                            3. n=1 odd: f(0)-1 = 0-1 = -1
                            4. n=2 even: f(1)+2 = -1+2 = 1
                            5. n=3 odd: f(2)-1 = 1-1 = 0
                            6. n=4 even: f(3)+4 = 0+4 = 4
                            7. Trap: using +n on every row, or skipping n=3. Answer 4.
                            """),
            MockQuestion(prompt: "x=7. if x>5 then x:=x-2. if x>5 then x:=x+10. Final x? (two separate IFs)", answer: "5",
                         derivation: """
                            1. Start x=7. Two separate ifs — the second sees the NEW x.
                            2. First: 7>5? Yes. x := 7-2 = 5.
                            3. Second: is 5>5? No. Skip x:=x+10.
                            4. Final x=5. Trap: using original 7 on both tests → 7-2=5 then 7>5 so +10 → 15. Wrong because x already changed.
                            """),
            MockQuestion(prompt: "a=3, b=8. if a<b then a:=a+b else b:=b-a. Then if a>10 then a:=a-5. Final a?", answer: "6",
                         derivation: """
                            1. Start a=3, b=8.
                            2. First fork: 3<8? Yes, take THEN: a := 3+8 = 11. ELSE (b:=b-a) does not run. b stays 8.
                            3. Second if (separate): a>10? 11>10 yes. a := 11-5 = 6.
                            4. They asked for a, not b. Answer 6.
                            """)
        ]),
        MockExam(contest: 1, title: "Contest 1 · Sitting C", questions: [
            MockQuestion(prompt: "How many bits are needed to write 100 in binary?", answer: "7",
                         derivation: """
                            1. This is NOT ‘how many 1s’. It is ‘how long is the binary string’.
                            2. Largest power of 2 ≤ 100 is 64. 100-64=36. Next 32. 36-32=4. Then 4. So 64+32+4.
                            3. Bits from 64 down to 1: 1 (64), 1 (32), 0 (16), 0 (8), 1 (4), 0 (2), 0 (1) → 1100100.
                            4. Count digits: 7. Check: 2^6=64, so numbers 64–127 need 7 bits. 100 is in that range.
                            """),
            MockQuestion(prompt: "Add 1A₁₆ + 7₁₆. Give the sum in hexadecimal.", answer: "21",
                         derivation: """
                            1. 1A₁₆ = 1×16 + 10 = 26 decimal (A=10).
                            2. 7₁₆ = 7 decimal.
                            3. 26+7=33 decimal.
                            4. 33 in hex: 2×16=32, remainder 1 → 21₁₆.
                            5. Hex add: A+7=10+7=17=11₁₆, write 1 carry 1. Then 1+carry 1=2. Same 21.
                            """),
            MockQuestion(prompt: "f(0)=1, f(n)=n+f(n-1). Find f(f(2)). Inside first.", answer: "11",
                         derivation: """
                            1. Inside first: find f(2), then f(of that).
                            2. f(0)=1
                               f(1)=1+1=2
                               f(2)=2+2=4
                            3. Now f(4). Continue:
                               f(3)=3+4=7
                               f(4)=4+7=11
                            4. Answer 11. Trap: saying 4 (forgot the outer f). Trap: saying 8 (did f twice as 2+2+2+2).
                            """),
            MockQuestion(prompt: "f(x,y)=f(x-1,y)+f(x,y-1), and f=1 if x=0 or y=0. Find f(2,2) using a grid.", answer: "6",
                         derivation: """
                            1. Draw x down, y across. Fill the 0-row with 1s. Fill the 0-column with 1s.
                            2. Each empty square = LEFT + ABOVE. Walk left to right, top to bottom.
                                   y0 y1 y2
                               x0   1  1  1
                               x1   1  2  3     (1+1=2, then 2+1=3)
                               x2   1  3  6     (1+2=3, then 3+3=6)
                            3. f(2,2) is the bottom-right square: 6.
                            4. Trap: 2+2=4 from the formula in your head without filling neighbors.
                            """),
            MockQuestion(prompt: "n=12. if n>10 then (if n>15 then n:=n-8 else n:=n-3) else n:=n+2. Final n?", answer: "9",
                         derivation: """
                            1. Outer test first: 12>10? Yes. Enter the INNER if. Outer else n:=n+2 is skipped.
                            2. Inner: 12>15? No. Take inner ELSE: n := 12-3 = 9.
                            3. Inner THEN (n-8) does not run.
                            4. Final n=9. Trap: +2 from the outer else (you already left that hallway). Trap: 12-8=4 (wrong inner branch).
                            """),
            MockQuestion(prompt: "h=4, k=1. if h is even then k:=k+h else k:=k-1. Then if k>4 then k:=k*2. Final k?", answer: "10",
                         derivation: """
                            1. h=4 is even, so THEN: k := 1+4 = 5. Else k-1 skipped.
                            2. Next if (separate): k>4? 5>4 yes. k := 5×2 = 10.
                            3. h never changes. They asked k. Answer 10.
                            """)
        ]),
        MockExam(contest: 1, title: "Contest 1 · Sitting D", questions: [
            MockQuestion(prompt: "Convert 3E₁₆ to octal (binary bridge).", answer: "76",
                         derivation: """
                            1. Hex digits to 4 bits: 3=0011. E=14=1110.
                            2. Glue: 00111110.
                            3. Octal: groups of 3 from the RIGHT. 00111110 is 8 bits; pad LEFT with 0: 000111110.
                            4. Groups: 000 111 110 = 0 7 6. Drop leading 0 → 76₈.
                            5. Check: 3E₁₆=3×16+14=62. 7×8+6=62. Matches.
                            """),
            MockQuestion(prompt: "Add 1011₂ + 1101₂. Give the sum in decimal.", answer: "24",
                         derivation: """
                            1. Convert each to decimal first (safest on paper).
                            2. 1011₂ = 8+0+2+1 = 11.
                            3. 1101₂ = 8+4+0+1 = 13.
                            4. 11+13=24. That is the answer they asked (decimal).
                            5. Binary add check: 1011+1101=11000₂ = 16+8=24. Same.
                            """),
            MockQuestion(prompt: "g(x)=g(x-3)+1 if x>0 else 3x. Find g(4).", answer: "-4",
                         derivation: """
                            1. Same rule as g(7) on Sitting A, different start. Stop when x≤0: g(x)=3x.
                            2. 4>0 → g(4)=g(1)+1
                            3. 1>0 → g(1)=g(-2)+1
                            4. -2≤0 → g(-2)=3×(-2)=-6
                            5. Back: g(1)=-6+1=-5. g(4)=-5+1=-4.
                            6. Two +1s, not three (g(7) had three steps). Answer -4, not -3.
                            """),
            MockQuestion(prompt: "g(0)=0, g(1)=1, g(n)=g(n-1)+g(n-2)+1. Find g(5). Two previous rows.", answer: "12",
                         derivation: """
                            1. TWO stop rows: write g(0)=0 and g(1)=1 before anything else.
                            2. g(2)=g(1)+g(0)+1 = 1+0+1 = 2
                            3. g(3)=g(2)+g(1)+1 = 2+1+1 = 4
                            4. g(4)=g(3)+g(2)+1 = 4+2+1 = 7
                            5. g(5)=g(4)+g(3)+1 = 7+4+1 = 12
                            6. Trap: Fibonacci without the extra +1 (would be 5). Trap: missing g(1) and jumping.
                            """),
            MockQuestion(prompt: "s=0. if 8>3 then s:=s+2. if 8>10 then s:=s+5 else s:=s+1. Final s?", answer: "3",
                         derivation: """
                            1. First line is a lone IF (no else): 8>3 true, s := 0+2 = 2.
                            2. Second line is IF/ELSE — exactly one branch. 8>10? False. Take ELSE: s := 2+1 = 3.
                            3. The THEN (+5) does not run.
                            4. Final s=3. Trap: both +2 and +5. Trap: skipping the first if because you saw an else later.
                            """),
            MockQuestion(prompt: "t=20. if t>=20 then t:=t/2. if t>=20 then t:=t+3. Two separate IFs. Final t?", answer: "10",
                         derivation: """
                            1. Start t=20. Two separate ifs; second uses NEW t.
                            2. First: 20>=20 yes. t := 20/2 = 10.
                            3. Second: 10>=20? No. Do not add 3.
                            4. Final t=10. Trap: 13 (halved then still added 3 using old t). Trap: 23 (both tests on original 20).
                            """)
        ]),
        MockExam(contest: 2, title: "Contest 2", questions: [
            MockQuestion(prompt: "Evaluate postfix: 3 4 + 5 *", answer: "35",
                         derivation: """
                            1. Postfix: read left to right. Numbers go on a stack. An operator pops two, computes, pushes the result.
                            2. See 3 → stack [3]. See 4 → [3, 4].
                            3. See + → pop 4 and 3, 3+4=7, push [7].
                            4. See 5 → [7, 5].
                            5. See * → pop 5 and 7, 7×5=35, push [35].
                            6. One number left: 35. (If you did 3+4×5 with infix order you might get 23 — wrong for postfix.)
                            """),
            MockQuestion(prompt: "Infix (3+4)*5 as postfix?", answer: "3 4 + 5 *",
                         derivation: """
                            1. Infix with parens: plus happens before times.
                            2. Operands stay in order: 3, then 4, then 5.
                            3. After 3 and 4 you need +, then after that product with 5 you need *.
                            4. Postfix: 3 4 + 5 *. Check by evaluating: 3 4 + → 7, then 7 5 * → 35, which matches (3+4)*5.
                            """),
            MockQuestion(prompt: "1011 AND 1101 (4 bits)", answer: "1001",
                         derivation: """
                            1. Line them up. AND is 1 only where BOTH bits are 1.
                               1 0 1 1
                            AND 1 1 0 1
                            2. Column by column: 1, 0, 0, 1 → 1001.
                            3. If lengths differ, ACSL pads 0s on the LEFT.
                            """),
            MockQuestion(prompt: "RCIRC-1 of 01101?", answer: "10110",
                         derivation: """
                            1. CIRC = rotate. Bits fall off one end and come back on the other. SHIFT would fill 0s instead.
                            2. RCIRC-1: rightmost bit moves to the front. 01101, last bit is 1.
                            3. Remaining 0110 gets that 1 in front: 10110.
                            4. Check length still 5. LCIRC-1 would have been 11010.
                            """),
            MockQuestion(prompt: "(RSHIFT-1 (LCIRC-4 (RCIRC-2 01101)))", answer: "01010",
                         derivation: """
                            1. Inside first. Start with 01101.
                            2. RCIRC-2 (rotate right twice):
                               RCIRC-1: 10110
                               RCIRC-2: 01011
                            3. LCIRC-4 of 01011 (rotate left four times, length 5):
                               LCIRC-1: 10110
                               LCIRC-2: 01101
                               LCIRC-3: 11010
                               LCIRC-4: 10101
                            4. RSHIFT-1 of 10101: bits move right, 0 fills the left. Rightmost 1 falls off → 01010.
                            5. Answer 01010.
                            """),
            MockQuestion(prompt: "ACSL: s=0; FOR i=1 TO 4 STEP 1; s=s+i; NEXT i. Output s?", answer: "10",
                         derivation: """
                            1. ACSL FOR includes BOTH ends. i = 1, 2, 3, 4. Not Python range(1,4).
                            2. s starts 0.
                               i=1: s=0+1=1
                               i=2: s=1+2=3
                               i=3: s=3+3=6
                               i=4: s=6+4=10
                            3. Answer 10. Trap: 6 from stopping before 4.
                            """)
        ]),

        MockExam(contest: 3, title: "Contest 3", questions: [
            MockQuestion(prompt: "Simplify (A+B)' using DeMorgan.", answer: "A'B'",
                         derivation: """
                            1. DeMorgan: break the bar and change + to · (AND), and put a bar on each piece.
                            2. (A+B)' = A' · B'. Written A'B'.
                            3. Dual reminder (not this answer): (AB)' = A'+B'.
                            """),
            MockQuestion(prompt: "Simplify A + A' · 1  (AND before OR).", answer: "1",
                         derivation: """
                            1. AND (·) before OR (+), like × before +.
                            2. A' · 1 = A'  (AND with 1 does nothing).
                            3. Now A + A'. Anything OR its complement is 1.
                            4. Answer 1, not A, not A'.
                            """),
            MockQuestion(prompt: "Stack: PUSH A, PUSH B, POP, PUSH C. Top to bottom (top first)?", answer: "C,A",
                         derivation: """
                            1. Stack = last in, first out. Top is the last push that was not popped.
                            2. PUSH A → [A] (A on top)
                            3. PUSH B → [B, A] (B on top)
                            4. POP → removes B → [A]
                            5. PUSH C → [C, A]
                            6. Top to bottom: C, A. B is gone.
                            """),
            MockQuestion(prompt: "Queue ENQ X, ENQ Y, DEQ. Front item?", answer: "Y",
                         derivation: """
                            1. Queue = first in, first out. Front is the oldest remaining item.
                            2. ENQ X → front X
                            3. ENQ Y → front X, then Y
                            4. DEQ removes the front (X). Front is now Y.
                            5. Answer Y. Trap: X (forgot the DEQ) or thinking stack so Y was popped.
                            """),
            MockQuestion(prompt: "1-based: A(1)=2, A(2)=4, A(3)=6. A(2)=A(1)+A(3). A(2)?", answer: "8",
                         derivation: """
                            1. ACSL arrays start at 1, not Python 0.
                            2. A(1)=2, A(3)=6. Sum 2+6=8.
                            3. Store that into A(2). Old A(2)=4 is overwritten.
                            4. Answer 8.
                            """),
            MockQuestion(prompt: "A(1,2) in ACSL 2-D arrays means?", answer: "row 1, column 2",
                         derivation: """
                            1. ACSL writes A(row, column). First number is the row, second is the column.
                            2. A(1,2) is row 1, column 2.
                            3. Not (column, row), and not Python a[1][2] zero-based.
                            """)
        ]),

        MockExam(contest: 4, title: "Contest 4", questions: [
            MockQuestion(prompt: "Undirected A-B-C. How many walks of length 2 from A to C?", answer: "1",
                         derivation: """
                            1. Path of edges: A—B—C. No extra edges.
                            2. A walk of length 2 is two hops. From A: A-B-A (back) or A-B-C.
                            3. Only A-B-C ends at C. Direct A-C would be length 1 and is not even an edge here.
                            4. Count: 1.
                            """),
            MockQuestion(prompt: "Directed edges AB,BA,BC,CD,DC,DB,DE. How many different cycles?", answer: "3",
                         derivation: """
                            1. A cycle returns to the start, no repeated vertex except start/end. Direction matters.
                            2. AB and BA: cycle A-B-A.
                            3. BC, CD, DB: cycle B-C-D-B.
                            4. CD and DC: cycle C-D-C.
                            5. DE has no way back from E, so no cycle through E.
                            6. Do not count A-B-A and B-A-B as two: same cycle. Total 3.
                            """),
            MockQuestion(prompt: "F = NOT(A AND B) OR C. Ordered triple that makes F FALSE?", answer: "1,1,0",
                         derivation: """
                            1. OR is false only if BOTH sides are false. So we need C=0 AND NOT(A AND B)=0.
                            2. NOT(A AND B)=0 means A AND B = 1, so A=1 and B=1.
                            3. Triple (A,B,C)=(1,1,0). Check: NOT(1 AND 1) OR 0 = NOT(1) OR 0 = 0 OR 0 = 0. F is false. That is the one they asked.
                            """),
            MockQuestion(prompt: "NAND of 1 and 1?", answer: "0",
                         derivation: """
                            1. NAND = NOT of AND.
                            2. 1 AND 1 = 1.
                            3. NOT 1 = 0.
                            4. NAND is 0 only on the pair 1,1. Any 0 in the inputs makes NAND 1.
                            """),
            MockQuestion(prompt: "S=ACSL WDTPD. ACSL paper S[2:6] (inclusive end)?", answer: "SL WD",
                         derivation: """
                            1. Write the string and number from 0 (this app’s Contest 4 habit, matching the wiki sample “SL WD”):
                               idx  0 1 2 3 4 5 6 7 8 9
                               S    A C S L   W D T P D
                               (index 4 is a space)
                            2. Paper S[2:6] keeps BOTH ends: indices 2,3,4,5,6.
                            3. Those characters: S, L, space, W, D → “SL WD”.
                            4. Python S[2:6] stops BEFORE 6: S, L, space, W → “SL W” (no D). That is the contest trap.
                            """),
            MockQuestion(prompt: "a=BANANAS reversed to t. How many j with a[j]==t[j]?", answer: "5",
                         derivation: """
                            1. a = B A N A N A S. Reverse t = S A N A N A B.
                            2. Line them up (1-based j=1..7):
                               j  1 2 3 4 5 6 7
                               a  B A N A N A S
                               t  S A N A N A B
                            3. Equal?  no yes yes yes yes yes no
                            4. Matches at j=2,3,4,5,6 → five positions. Answer 5.
                            """)
        ])
    ]
}

#Preview("ACSL Junior Coach") {
    ACSLJuniorCoachRootView()
        .frame(width: 1200, height: 800)
}
