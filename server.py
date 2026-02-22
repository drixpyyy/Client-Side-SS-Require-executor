from flask import Flask, request, jsonify
import json
import os
import time

app = Flask(__name__)
DATA_FOLDER = "server_data"

# Ensure data folder exists
if not os.path.exists(DATA_FOLDER):
    os.makedirs(DATA_FOLDER)

# --- SERVER STATE ---
# This mimics the Roblox Server's memory
ServerState = {
    "Initialized": False,
    "StartTime": time.time(),
    "GlobalValues": {},
    "RemoteQueue": [] # Messages waiting to be sent to Client
}

# --- DATASTORE ENDPOINTS ---
@app.route('/get_async', methods=['POST'])
def get_async():
    data = request.json
    path = os.path.join(DATA_FOLDER, f"{data.get('datastore')}.json")
    if os.path.exists(path):
        with open(path, 'r') as f:
            store = json.load(f)
            return jsonify({"value": store.get(data.get('key'))})
    return jsonify({"value": None})

@app.route('/set_async', methods=['POST'])
def set_async():
    data = request.json
    path = os.path.join(DATA_FOLDER, f"{data.get('datastore')}.json")
    store = {}
    if os.path.exists(path):
        with open(path, 'r') as f:
            try: store = json.load(f)
            except: pass
    store[data.get('key')] = data.get('value')
    with open(path, 'w') as f:
        json.dump(store, f, indent=4)
    return jsonify({"success": True})

# --- NETWORKING ENDPOINTS (The "Real" Server) ---

@app.route('/init_server', methods=['POST'])
def init_server():
    # The Lua script calls this when it starts to tell Python "I am alive"
    ServerState["Initialized"] = True
    print(" [SERVER] Virtual Game Server Started.")
    return jsonify({"status": "Running", "jobId": "VIRTUAL-JOB-1"})

@app.route('/fire_server', methods=['POST'])
def fire_server():
    # Lua Client -> Python Server
    data = request.json
    remote_name = data.get('remote')
    args = data.get('args')
    print(f" [NET] Client fired remote: {remote_name} with args: {args}")
    
    # Logic: If the client asks "IsServerReady?", we reply YES
    if remote_name == "CheckServer":
        ServerState["RemoteQueue"].append({
            "remote": "ServerReadyResponse",
            "args": [True]
        })
        
    return jsonify({"success": True})

@app.route('/poll_client', methods=['GET'])
def poll_client():
    # Python Server -> Lua Client
    # The Lua script asks this every 0.1s: "Do you have tasks for me?"
    queue = ServerState["RemoteQueue"]
    ServerState["RemoteQueue"] = [] # Clear queue after sending
    return jsonify({"events": queue})

if __name__ == '__main__':
    print(" :: Virtual Roblox Engine Running on Port 5000 :: ")
    app.run(port=5000)
