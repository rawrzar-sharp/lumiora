#!/bin/bash
# 1. Update and install core dependencies
sudo apt-get update -y
sudo apt-get install git python3-pip python3-venv -y

# 2. Clone your API repository
git clone https://github.com/rawrzar-sharp/lumiora.git
cd lumiora

# 3. Setup Virtual Environment and Dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. (Optional) Install a process manager to keep the API alive
sudo apt install npm -y
sudo npm install pm2 -g

# 5. Start your API
# Adjust 'python server.py' to your project's entry point
pm2 start server.py --interpreter venv/bin/python
pm2 save