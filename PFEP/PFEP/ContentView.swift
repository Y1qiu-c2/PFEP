import SwiftUI

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var projectNames: [String]  // 新增项目名称数组
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
                // 显示保存的任务
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
                                        .frame(maxWidth: .infinity, alignment: .leading)  // 使任务名称靠左对齐
                                    
                                    Text(String(format: "%.2f%%", savedTasks[index].weightedCompletionRatio * 100))
                                        .font(.system(size: 32, weight: .bold))  // 更大的粗体字体显示完成比
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)  // 使完成比靠左对齐
                                }
                                .padding()
                                .frame(maxWidth: .infinity)  // 使框变得更长
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding(.bottom, 10)  // 每个任务框之间增加一些间距
                        }
                    }
                    .padding()
                }

                // 新建任务按钮
                NavigationLink(destination: NewTaskView(savedTasks: $savedTasks)) {
                    Text("新建任务")
                        .font(.headline)
                        .frame(maxWidth: .infinity) // 按钮宽度占满屏幕
                        .frame(height: 60) // 设置按钮高度
                        .background(Color.green.opacity(0.7)) // 浅绿色背景
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
struct NewTaskView: View {
    @Binding var savedTasks: [Task]
    @Environment(\.presentationMode) var presentationMode
    @State private var taskNameForTitle: String = ""
    @State private var projectNames: [String] = [""]  // 初始项目名称
    @State private var taskCount: [String] = [""]
    @State private var singleTime: [String] = [""]
    @State private var completedCounts: [String] = ["0"]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSavePrompt = false

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
                Button(action: {
                    if completedCounts.count > 1 {
                        projectNames.removeLast()
                        taskCount.removeLast()
                        singleTime.removeLast()
                        completedCounts.removeLast()
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
                Button(action: {
                    projectNames.append("")  // 添加新的项目名称
                    taskCount.append("")
                    singleTime.append("")
                    completedCounts.append("0")
                }) {
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
                    TextField("输入项目名称", text: $projectNames[index])  // 绑定项目名称
                    TextField("输入项目数量", text: $taskCount[index])
                        .keyboardType(.numberPad)
                        .onChange(of: taskCount[index]) {
                            if !isValidNumber($0) {
                                showError(message: "项目数量必须为数字")
                                taskCount[index] = ""
                            }
                        }
                    TextField("输入单项时间", text: $singleTime[index])
                        .keyboardType(.numberPad)
                        .onChange(of: singleTime[index]) {
                            if !isValidNumber($0) {
                                showError(message: "单项时间必须为数字")
                                singleTime[index] = ""
                            }
                        }
                    TextField("完成数量", text: $completedCounts[index])
                        .keyboardType(.numberPad)
                        .onChange(of: completedCounts[index]) {
                            if !isValidNumber($0) {
                                showError(message: "完成数量必须为数字")
                                completedCounts[index] = "0"
                            }
                        }
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("保存") {
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

    func isValidNumber(_ value: String) -> Bool {
        return value.isEmpty || Int(value) != nil
    }

    func showError(message: String) {
        alertMessage = message
        showAlert = true
    }

    func saveTask() {
        if taskNameForTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            taskNameForTitle = dateFormatter.string(from: Date())
        }

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

        let weightedCompletionRatio = totalTime > 0 ? 1.0 - Double(totalRemainingTime) / Double(totalTime) : 0.0

        // 初始化 Task 实例时传递所有参数，包括项目名称
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
    @Binding var savedTasks: [Task]  // 用于传递整个任务列表，以便在删除任务时更新
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false  // 控制删除确认对话框的显示

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("任务名称：")
                    .font(.headline)
                TextField("输入任务名称", text: $task.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
            }
            .padding()

            HStack {
                Button(action: {
                    if task.completedCounts.count > 1 {
                        task.projectNames.removeLast()
                        task.taskCount.removeLast()
                        task.singleTime.removeLast()
                        task.completedCounts.removeLast()
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
                Button(action: {
                    task.projectNames.append("")  // 添加新的项目名称
                    task.taskCount.append("")
                    task.singleTime.append("")
                    task.completedCounts.append("0")
                }) {
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

                ForEach(0..<task.completedCounts.count, id: \.self) { index in
                    TextField("输入项目名称", text: $task.projectNames[index])  // 绑定项目名称
                    TextField("输入项目数量", text: $task.taskCount[index])
                        .keyboardType(.numberPad)
                        .onChange(of: task.taskCount[index]) {
                            if !isValidNumber($0) {
                                showError(message: "项目数量必须为数字")
                                task.taskCount[index] = ""
                            }
                        }
                    TextField("输入单项时间", text: $task.singleTime[index])
                        .keyboardType(.numberPad)
                        .onChange(of: task.singleTime[index]) {
                            if !isValidNumber($0) {
                                showError(message: "单项时间必须为数字")
                                task.singleTime[index] = ""
                            }
                        }
                    TextField("完成数量", text: $task.completedCounts[index])
                        .keyboardType(.numberPad)
                        .onChange(of: task.completedCounts[index]) {
                            if !isValidNumber($0) {
                                showError(message: "完成数量必须为数字")
                                task.completedCounts[index] = "0"
                            }
                        }
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("删除") {
                    showDeleteConfirmation = true  // 显示删除确认对话框
                }
                .font(.headline)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()

                Button("保存") {
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
                secondaryButton: .cancel(Text("取消"))  // 将 cancel 按钮的文字改为“取消”
            )
        }
    }

    func isValidNumber(_ value: String) -> Bool {
        return value.isEmpty || Int(value) != nil
    }

    func showError(message: String) {
        alertMessage = message
        showAlert = true
    }

    func saveTask() {
        let totalRemainingTime = zip(task.taskCount, task.singleTime).enumerated().reduce(0) { result, item in
            let (index, (s_i, t_i)) = item
            let f_i = Int(task.completedCounts[index]) ?? 0
            let s_i_value = Int(s_i) ?? 0
            let t_i_value = Int(t_i) ?? 0
            return result + (s_i_value - f_i) * t_i_value
        }

        let totalTime = zip(task.taskCount, task.singleTime).reduce(0) { result, item in
            let (s_i, t_i) = item
            let s_i_value = Int(s_i) ?? 0
            let t_i_value = Int(t_i) ?? 0
            return result + s_i_value * t_i_value
        }

        task.weightedCompletionRatio = totalTime > 0 ? 1.0 - Double(totalRemainingTime) / Double(totalTime) : 0.0
    }

    func deleteTask() {
        if let index = savedTasks.firstIndex(where: { $0.id == task.id }) {
            savedTasks.remove(at: index)  // 从任务列表中删除任务
        }
        presentationMode.wrappedValue.dismiss()
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
