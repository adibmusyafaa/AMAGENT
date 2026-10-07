import sys
import os
import json
import socket
import bcrypt
import win32com.client
from flask import Flask, request, jsonify
from flask_cors import CORS
import qrcode
import base64
from io import BytesIO
import uuid
import psutil

CONFIG_PATH = "config.json"
app = Flask(__name__)
CORS(app)

class AmagentServer:
    def __init__(self):
        self.password_hash = self._load_password()
        self.active_client_id = None  # SINGLE DEVICE LOCK
        self.allowed_apps = []
        self.allowed_files = []

    def _load_password(self):
        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, "r") as f:
                return json.load(f).get("hash")
        return None

    def set_password(self, password):
        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        with open(CONFIG_PATH, "w") as f:
            json.dump({"hash": hashed}, f)
        self.password_hash = hashed

    def verify(self, password):
        if not self.password_hash: return False
        return bcrypt.checkpw(password.encode(), self.password_hash.encode())

    def get_qr_data(self):
        ip = socket.gethostbyname(socket.gethostname())
        # AMAGENT protocol info for the mobile scanner
        data = f"AMAGENT|{ip}|8888"
        qr = qrcode.make(data)
        buffered = BytesIO()
        qr.save(buffered, format="PNG")
        return base64.b64encode(buffered.getvalue()).decode()

server_logic = AmagentServer()

@app.route("/qr", methods=["GET"])
def get_qr():
    return jsonify({"qr_base64": server_logic.get_qr_data()})

@app.route("/pair", methods=["POST"])
def pair():
    data = request.json
    if server_logic.active_client_id:
        return jsonify({"error": "LOCKED: Another device is currently connected"}), 403
    
    if not server_logic.verify(data.get("password", "")):
        return jsonify({"error": "Invalid Master Password"}), 401
    
    client_id = str(uuid.uuid4())
    server_logic.active_client_id = client_id
    return jsonify({"status": "paired", "client_id": client_id})

@app.route("/command", methods=["POST"])
def command():
    data = request.json
    client_id = data.get("client_id")
    
    if not client_id or client_id != server_logic.active_client_id:
        return jsonify({"error": "Unauthorized: This device is not the active controller"}), 403

    cmd = data["command"].lower()
    
    try:
        # PPT Control
        ppt = win32com.client.GetActiveObject("PowerPoint.Application")
        presentation = ppt.ActivePresentation
        
        if any(x in cmd for x in ["halaman", "page", "slide"]):
            page_match = ''.join(filter(str.isdigit, cmd))
            if page_match:
                page = int(page_match)
                presentation.SlideShowWindow.View.GotoSlide(page)
                return jsonify({"status": "success", "action": f"jump to page {page}"})
            
        if "next" in cmd or "berikut" in cmd:
            presentation.SlideShowWindow.View.Next()
            return jsonify({"status": "success", "action": "next slide"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify({"status": "received", "command": cmd})

@app.route("/disconnect", methods=["POST"])
def disconnect():
    data = request.json
    if data.get("client_id") == server_logic.active_client_id:
        server_logic.active_client_id = None
        return jsonify({"status": "disconnected"})
    return jsonify({"error": "Unauthorized"}), 401

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8888)
