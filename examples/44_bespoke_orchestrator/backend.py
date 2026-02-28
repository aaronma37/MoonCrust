import socket
import json
import time
import random
import math

# --- CONFIGURATION ---
UDP_IP = "127.0.0.1"
UDP_PORT = 5555
BROADCAST_INTERVAL = 0.05  # 20Hz telemetry

# --- SIMULATED STATE ---
class OrchestratorSimulator:
    def __init__(self):
        self.agents = [
            {"id": 1, "name": "Sync-Worker-A", "status": "Running", "progress": 0.0},
            {"id": 2, "name": "LLM-Inference-01", "status": "Running", "progress": 0.0},
            {"id": 3, "name": "Webhook-Listener", "status": "Idle", "progress": 0.0},
            {"id": 4, "name": "Video-Transcoder", "status": "Running", "progress": 0.0},
            {"id": 5, "name": "Database-Cleaner", "status": "Running", "progress": 0.0},
        ]
        self.start_time = time.time()
        self.concurrency = 0

    def step(self):
        elapsed = time.time() - self.start_time
        self.concurrency = 800 + 200 * math.sin(elapsed * 0.5) + random.uniform(-10, 10)
        
        for agent in self.agents:
            if agent["status"] == "Running":
                agent["progress"] += random.uniform(0.001, 0.01)
                if agent["progress"] >= 1.0:
                    agent["progress"] = 0.0
                    if random.random() > 0.95:
                        agent["status"] = "Error"
            elif agent["status"] == "Error":
                if random.random() > 0.9:
                    agent["status"] = "Running"
            elif agent["status"] == "Idle":
                if random.random() > 0.98:
                    agent["status"] = "Running"

    def get_telemetry(self):
        return {
            "timestamp": time.time(),
            "concurrency": self.concurrency,
            "latency_ms": 15 + (self.concurrency / 100.0) + random.uniform(0, 5),
            "agents": self.agents,
            "logs": [
                f"[INFO] Processed {int(random.uniform(10, 100))} tasks in last bucket.",
                f"[DEBUG] Memory footprint: {int(random.uniform(128, 512))} MB"
            ] if random.random() > 0.8 else []
        }

def main():
    print(f"🚀 Bespoke Orchestrator Backend Simulator")
    print(f"📡 Broadcasting telemetry to {UDP_IP}:{UDP_PORT}...")
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sim = OrchestratorSimulator()

    try:
        while True:
            sim.step()
            telemetry = sim.get_telemetry()
            data = json.dumps(telemetry).encode('utf-8')
            sock.sendto(data, (UDP_IP, UDP_PORT))
            time.sleep(BROADCAST_INTERVAL)
    except KeyboardInterrupt:
        print("\n🛑 Shutting down backend.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
