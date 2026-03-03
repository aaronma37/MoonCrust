import socket
import json
import time
import os

# CONFIGURATION
KERNEL_IP = "127.0.0.1"
KERNEL_LISTEN_PORT = 5555
BACKEND_LISTEN_PORT = 5556

# Initialize Socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", BACKEND_LISTEN_PORT))

print(f"🚀 MoonCrust Gemini Backend active on port {BACKEND_LISTEN_PORT}")

def send_to_kernel(data):
    msg = json.dumps(data)
    sock.sendto(msg.encode(), (KERNEL_IP, KERNEL_LISTEN_PORT))

while True:
    try:
        data, addr = sock.recvfrom(4096)
        msg = json.loads(data.decode())
        
        if msg["type"] == "agent_query":
            payload = msg["payload"]
            node_id = payload["node_id"]
            prompt = payload["prompt"]
            kernel_input = payload["input"]
            
            print(f"🧠 Reasoning requested for Node {node_id}...")
            
            # --- REAL GEMINI INTEGRATION POINT ---
            # if API_KEY:
            #    response = gemini.generate(prompt + str(kernel_input))
            #    res_text = response.text
            # else:
            res_text = f"REAL-TIME ANALYSIS: Kernel latency is {kernel_input.get('latency', 0):.2f}ms. Suggesting optimization pass Alpha-7."
            
            # Send update back to kernel
            send_to_kernel({
                "type": "node_update",
                "node_id": node_id,
                "messages": [
                    {"time": int(time.time()), "data": "[REAL GEMINI] " + res_text}
                ]
            })
            print(f"✅ Reasoning delivered to Node {node_id}")

    except Exception as e:
        print(f"❌ Backend Error: {e}")
