#!/bin/bash
echo "--- AMAGENT Windows Build Start ---"
cd server
python -m pip install --upgrade pip
pip install -r requirements.txt
pyinstaller --noconsole --onefile --name amagent main.py
echo "--- Build Finished! Check server/dist/amagent.exe ---"
read -p "Press enter to exit"
