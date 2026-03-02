import socket
import json
import time
import random
import math
import threading

# --- CONFIGURATION ---
UDP_IP = "127.0.0.1"
TELEMETRY_PORT = 5555
COMMAND_PORT = 5556
BROADCAST_INTERVAL = 0.05  # 20Hz telemetry

class OrchestratorSimulator:
    def __init__(self):
        self.agents = [
            {"id": i, "name": f"Agent-{i}", "status": "Running", "progress": 0.0} for i in range(1, 6)
        ]
        self.start_time = time.time()
        self.concurrency = 0
        self.logs = []
        
        # Node message buffers
        self.node_queues = { i: [] for i in range(1, 200) }
        self.graph = {
            "links": [
                {"start": 1, "end": 2}, {"start": 2, "end": 3},
                {"start": 2, "end": 4}, {"start": 3, "end": 5},
                {"start": 4, "end": 5}
            ]
        }

    def step(self):
        elapsed = time.time() - self.start_time
        self.concurrency = 800 + 200 * math.sin(elapsed * 0.5) + random.uniform(-10, 10)
        
        # Simulate Message Propagation
        # If a node has messages, 'process' them and move to connected nodes
        for link in self.graph["links"]:
            src = link["start"]
            dst = link["end"]
            if self.node_queues[src] and random.random() > 0.9: # 10% chance to move a message per step
                msg = self.node_queues[src].pop(0)
                self.node_queues[dst].append(f"Processed: {msg}")
                self.logs.append(f"[FLOW] Msg moved {src} -> {dst}")

    def get_telemetry(self):
        t = {
            "timestamp": time.time(),
            "concurrency": self.concurrency,
            "latency_ms": 15 + (self.concurrency / 100.0) + random.uniform(0, 5),
            "agents": self.agents,
            "logs": self.logs[:]
        }
        self.logs = []
        return t

    def handle_command(self, cmd_data):
        try:
            cmd = json.loads(cmd_data)
            ctype = cmd.get("type")
            payload = cmd.get("payload")
            
            if ctype == "run_optimizer":
                self.logs.append("[AI] Dreaming of new architectures...")
                threading.Timer(1.5, self.send_shadow_proposal).start()
            elif ctype == "inject_event":
                nid = payload.get("node_id")
                data = payload.get("data")
                self.node_queues[nid].append(data)
                self.logs.append(f"[CMD] Injected event into Node {nid}")
            elif ctype == "sync_graph":
                # Convert links to backend format
                new_links = []
                for l in payload.get("links", []):
                    new_links.append({"start": l["start"], "end": l["end_node"]})
                self.graph["links"] = new_links
                self.logs.append(f"[CMD] Backend graph synchronized. {len(new_links)} links.")
            elif ctype == "restart_agents":
                self.logs.append("[CMD] Agents reset.")
        except Exception as e:
            self.logs.append(f"[ERROR] {e}")

    def send_shadow_proposal(self):
        proposal = {
            "type": "shadow_proposal",
            "nodes": [
                { "id": 101, "type": "llm", "name": "Critique Agent", "color": [0.8, 0.2, 0.2, 1], "expanded": True, "messages": [], "config": {"model":"gpt-4o", "temp":0, "prompt": "Identify flaws in logic."} }
            ],
            "links": [
                { "id": 201, "start": 3, "end_node": 101 },
                { "id": 202, "start": 101, "end_node": 5 }
            ]
        }
        self.broadcast_message(proposal)

    def broadcast_message(self, msg):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(json.dumps(msg).encode('utf-8'), (UDP_IP, TELEMETRY_PORT))
        sock.close()

def command_listener(sim):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, COMMAND_PORT))
    while True:
        data, addr = sock.recvfrom(8192)
        sim.handle_command(data.decode('utf-8'))

def main():
    sim = OrchestratorSimulator()
    threading.Thread(target=command_listener, args=(sim,), daemon=True).start()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    print(f"🚀 Orchestrator Backend: {UDP_IP}:{TELEMETRY_PORT} (Telemetry) / {COMMAND_PORT} (Commands)")

    try:
        while True:
            sim.step()
            
            # 1. Send periodic telemetry
            telemetry = sim.get_telemetry()
            sock.sendto(json.dumps(telemetry).encode('utf-8'), (UDP_IP, TELEMETRY_PORT))
            
            # 2. Send per-node queue updates for the "Activity Pulse"
            for nid, queue in sim.node_queues.items():
                if len(queue) > 0 or random.random() > 0.95: # Pulsing updates
                     update = {
                         "type": "node_update",
                         "node_id": nid,
                         "messages": queue
                     }
                     sock.sendto(json.dumps(update).encode('utf-8'), (UDP_IP, TELEMETRY_PORT))

            time.sleep(BROADCAST_INTERVAL)
    except KeyboardInterrupt:
        pass
    finally:
        sock.close()

if __name__ == "__main__":
    main()
