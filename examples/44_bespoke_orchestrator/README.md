# 🌙 MoonCrust Bespoke Orchestrator

A high-performance, self-evolving orchestration engine that decouples a **Vulkan/ImGui frontend** from a **multi-process Lua backend**. This system is designed to be cloned into independent "evolved" sandboxes where an **AI Overseer** can autonomously rewrite the system's logic.

## 🏗️ Cloning the Scaffold

To create a new, independent orchestration project from this scaffold, use the `clone_orchestrator.sh` script located in the project root.

### Command:
```bash
./clone_orchestrator.sh <destination_directory>
```

### Example:
```bash
./clone_orchestrator.sh examples/my_autonomous_agent
```

This will:
1. Create the destination directory.
2. Replicate the backend, frontend, and worker logic.
3. Initialize a `nodes/generated` folder with full permissions for the AI Architect.

---

## 🚀 Launching the Application

You can launch the orchestrator targeting any cloned directory (or the original scaffold) using the master `launch.sh` script.

### Command:
```bash
./examples/44_bespoke_orchestrator/launch.sh [target_directory]
```

*   If `target_directory` is omitted, it defaults to the original scaffold (`examples/44_bespoke_orchestrator`).

### Examples:

**Run the original scaffold:**
```bash
./examples/44_bespoke_orchestrator/launch.sh
```

**Run your cloned/evolved version:**
```bash
./examples/44_bespoke_orchestrator/launch.sh examples/my_autonomous_agent
```

---

## ⚙️ How it Works

1.  **Backend Initialization**: The `launch.sh` script starts the `backend.lua` process, which manages the lifecycle of all graph nodes.
2.  **Frontend Visualization**: The MoonCrust kernel launches `main.lua`, providing a real-time Vulkan-based dashboard of the system state.
3.  **Active Heartbeat**: By default, the system pulses every 5 seconds. It uses a **Synchronized Pulse** mechanism—the next heartbeat will only trigger once the **Overseer** has finished its architectural analysis of the current run.
4.  **Self-Evolution**: Every pulse, the **Overseer** node analyzes the execution logs. It can autonomously write new Lua code to `nodes/generated/` and command the backend to hot-swap these nodes into the running DAG.

---

## 🛠️ Troubleshooting

*   **Worker Logs**: If a node isn't behaving, check its individual log in `/tmp/`:
    `cat /tmp/mc_node_[ID].log`
*   **Backend Routing**: Follow the global routing and mutation logs:
    `tail -f /tmp/mooncrust_backend.log`
*   **UDP Ports**: The system uses UDP ports `5555`, `5556`, and `5557`. Ensure these are not blocked or in use by other processes.
