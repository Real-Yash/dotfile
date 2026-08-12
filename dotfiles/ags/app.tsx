import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createState, For } from "ags"
import { execAsync } from "ags/process"

type TaskItem = {
  id: number
  description: string
}

const [tasks, setTasks] = createState<TaskItem[]>([])
const [newTask, setNewTask] = createState("")

async function refreshTasks() {
  try {
    const output = await execAsync([
      "/bin/sh",
      "-c",
      `task status:pending export | jq -c '[.[] | {id, description}]'`,
    ])

    setTasks(JSON.parse(output))
  } catch (err) {
    console.error("Failed loading tasks:", err)
  }
}

async function addTask() {
  const text = newTask().trim()
  if (!text) return

  await execAsync([
    "task",
    "add",
    text,
  ])

  setNewTask("")
  await refreshTasks()
}

async function completeTask(id: number) {
  await execAsync([
    "task",
    `${id}`,
    "done",
  ])

  await refreshTasks()
}

async function deleteTask(id: number) {
  await execAsync([
    "task",
    "rc.confirmation=off",
    `${id}`,
    "delete",
  ])

  await refreshTasks()
}

function TaskPopup() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="TaskPopup"
      application={app}
      visible={false}
      namespace="task-popup"
      anchor={TOP | RIGHT}
      keymode={Astal.Keymode.ON_DEMAND}
      exclusivity={Astal.Exclusivity.NORMAL}
      marginTop={42}
      marginRight={10}
	$={(self) => app.add_window(self)}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={10}
        css="
          min-width: 390px;
          padding: 16px;
          background: #11111b;
          border-radius: 16px;
        "
      >
        <box>
          <label
            label="Tasks"
            hexpand
            halign={Gtk.Align.START}
            css="font-size: 18px; font-weight: bold;"
          />

          <button
            label="✕"
            onClicked={() =>
              app.get_window("TaskPopup")?.hide()
            }
          />
        </box>

        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={6}
        >
          <For each={tasks}>
            {(task) => (
              <box
                spacing={8}
                css="
                  padding: 8px;
                  background: #181825;
                  border-radius: 10px;
                "
              >
                <button
                  label="✓"
                  onClicked={() =>
                    completeTask(task.id)
                  }
                />

                <label
                  label={task.description}
                  hexpand
                  halign={Gtk.Align.START}
                  wrap
                />

                <button
                  label="🗑"
                  onClicked={() =>
                    deleteTask(task.id)
                  }
                />
              </box>
            )}
          </For>
        </box>

        <box spacing={8}>
<entry
  hexpand
  placeholderText="Add a task..."
  text={newTask}
  onNotifyText={(self) => setNewTask(self.text)}
  onActivate={() => addTask()}
/>
          <button
            label="+"
            onClicked={() =>
              addTask()
            }
          />
        </box>
      </box>
    </window>
  )
}

app.start({
  main() {
    TaskPopup()
    refreshTasks()

    setInterval(refreshTasks, 5000)
  },
})
