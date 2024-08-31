import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var projectNames: [String]
    var taskCount: [String]
    var singleTime: [String]
    var completedCounts: [String]
    var weightedCompletionRatio: Double
}

struct ContentView: View {
    @State private var savedTasks: [Task] = []

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if !savedTasks.isEmpty {
                    VStack(alignment: .leading) {
                        Text("已保存的任务")
                            .font(.headline)
                            .padding(.bottom, 5)

                        ForEach(savedTasks.indices, id: \.self) { index in
                            NavigationLink(destination: EditTaskView(task: $savedTasks[index], savedTasks: $savedTasks)) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(savedTasks[index].name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text(String(format: "%.2f%%", savedTasks[index].weightedCompletionRatio * 100))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    .padding()
                }

                NavigationLink(destination: NewTaskView(savedTasks: $savedTasks)) {
                    Text("新建任务")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationTitle("首页")
        }
    }
}

struct TaskDetailView: View {
    @Binding var taskNameForTitle: String
    @Binding var projectNames: [String]
    @Binding var taskCount: [String]
    @Binding var singleTime: [String]
    @Binding var completedCounts: [String]

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("任务名称：")
                    .font(.headline)
                TextField("输入任务名称", text: $taskNameForTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
            }
            .padding()

            HStack {
                Button(action: removeProject) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
                Button(action: addProject) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }
            }
            .padding(.bottom)

            LazyVGrid(columns: columns, spacing: 16) {
                Text("项目名称").font(.headline)
                Text("项目数量").font(.headline)
                Text("单项时间").font(.headline)
                Text("完成数量").font(.headline)

                ForEach(0..<completedCounts.count, id: \.self) { index in
                    TextField("输入项目名称", text: $projectNames[index])
                    TextField("输入项目数量", text: $taskCount[index])
                    TextField("输入单项时间", text: $singleTime[index])
                    TextField("输入完成数量", text: $completedCounts[index])
                }
            }
            .padding(.horizontal)
        }
    }

    func addProject() {
        projectNames.append("")
        taskCount.append("")
        singleTime.append("")
        completedCounts.append("")
    }

    func removeProject() {
        if completedCounts.count > 1 {
            projectNames.removeLast()
            taskCount.removeLast()
            singleTime.removeLast()
            completedCounts.removeLast()
        }
    }
}

struct NewTaskView: View {
    @Binding var savedTasks: [Task]
    @Environment(\.presentationMode) var presentationMode
    @State private var taskNameForTitle: String = ""
    @State private var projectNames: [String] = [""]
    @State private var taskCount: [String] = [""]
    @State private var singleTime: [String] = [""]
    @State private var completedCounts: [String] = [""]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSavePrompt = false

    var body: some View {
        VStack(alignment: .leading) {
            TaskDetailView(
                taskNameForTitle: $taskNameForTitle,
                projectNames: $projectNames,
                taskCount: $taskCount,
                singleTime: $singleTime,
                completedCounts: $completedCounts
            )

            Spacer()

            HStack {
                Button("保存") {
                    let errorMessage = validateInputs(taskName: taskNameForTitle, projectNames: projectNames, taskCount: taskCount, singleTime: singleTime, completedCounts: completedCounts)
                    if let errorMessage = errorMessage {
                        alertMessage = errorMessage
                        showAlert = true
                        return
                    }
                    saveTask()
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()

                Button("退出") {
                    showSavePrompt = true
                }
                .font(.headline)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .navigationTitle(taskNameForTitle.isEmpty ? "新建任务" : taskNameForTitle)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("输入错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .alert(isPresented: $showSavePrompt) {
            Alert(
                title: Text("是否保存?"),
                message: Text("您有未保存的更改。是否在返回首页前保存？"),
                primaryButton: .default(Text("保存"), action: {
                    saveTask()
                }),
                secondaryButton: .destructive(Text("不保存"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
    }

    func saveTask() {
        if taskNameForTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            taskNameForTitle = dateFormatter.string(from: Date())
        }

        let weightedCompletionRatio = calculateCompletionRatio(taskCount: taskCount, singleTime: singleTime, completedCounts: completedCounts)

        let task = Task(
            name: taskNameForTitle,
            projectNames: projectNames,
            taskCount: taskCount,
            singleTime: singleTime,
            completedCounts: completedCounts,
            weightedCompletionRatio: weightedCompletionRatio
        )
        savedTasks.append(task)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditTaskView: View {
    @Binding var task: Task
    @Binding var savedTasks: [Task]
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading) {
            TaskDetailView(
                taskNameForTitle: $task.name,
                projectNames: $task.projectNames,
                taskCount: $task.taskCount,
                singleTime: $task.singleTime,
                completedCounts: $task.completedCounts
            )

            Spacer()

            HStack {
                Button("删除") {
                    showDeleteConfirmation = true
                }
                .font(.headline)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()

                Button("保存") {
                    let errorMessage = validateInputs(taskName: task.name, projectNames: task.projectNames, taskCount: task.taskCount, singleTime: task.singleTime, completedCounts: task.completedCounts)
                    if let errorMessage = errorMessage {
                        alertMessage = errorMessage
                        showAlert = true
                        return
                    }
                    saveTask()
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .navigationTitle(task.name.isEmpty ? "编辑任务" : task.name)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("输入错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("删除任务"),
                message: Text("您确定要删除此任务吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteTask()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    func saveTask() {
        task.weightedCompletionRatio = calculateCompletionRatio(taskCount: task.taskCount, singleTime: task.singleTime, completedCounts: task.completedCounts)
        presentationMode.wrappedValue.dismiss()
    }

    func deleteTask() {
        if let index = savedTasks.firstIndex(where: { $0.id == task.id }) {
            savedTasks.remove(at: index)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// Helper function to combine four collections into a tuple array
func zip4<A, B, C, D>(_ a: [A], _ b: [B], _ c: [C], _ d: [D]) -> [(A, B, C, D)] {
    let count = min(a.count, b.count, c.count, d.count)
    var result: [(A, B, C, D)] = []
    for i in 0..<count {
        result.append((a[i], b[i], c[i], d[i]))
    }
    return result
}

// Function to calculate completion ratio for a task
func calculateCompletionRatio(taskCount: [String], singleTime: [String], completedCounts: [String]) -> Double {
    let totalRemainingTime = zip(taskCount, singleTime).enumerated().reduce(0) { result, item in
        let (index, (s_i, t_i)) = item
        let f_i = Int(completedCounts[index]) ?? 0
        let s_i_value = Int(s_i) ?? 0
        let t_i_value = Int(t_i) ?? 0
        return result + (s_i_value - f_i) * t_i_value
    }

    let totalTime = zip(taskCount, singleTime).reduce(0) { result, item in
        let (s_i, t_i) = item
        let s_i_value = Int(s_i) ?? 0
        let t_i_value = Int(t_i) ?? 0
        return result + s_i_value * t_i_value
    }

    return totalTime > 0 ? 1.0 - Double(totalRemainingTime) / Double(totalTime) : 0.0
}

// Input validation function
func validateInputs(taskName: String, projectNames: [String], taskCount: [String], singleTime: [String], completedCounts: [String]) -> String? {
    if taskName.trimmingCharacters(in: .whitespaces).isEmpty {
        return "任务名称不能为空"
    }
    
    for (name, count, time, completed) in zip4(projectNames, taskCount, singleTime, completedCounts) {
        if name.trimmingCharacters(in: .whitespaces).isEmpty || count.isEmpty || time.isEmpty || completed.isEmpty {
            return "项目名称、项目数量、单项时间和完成数量均不可为空"
        }
    }
    
    return nil
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
