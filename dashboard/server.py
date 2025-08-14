#!/usr/bin/env python3

"""
Turnkey Deployment Dashboard Server
Simple Flask server to serve the dashboard and handle deployment API calls
"""

import os
import sys
import json
import subprocess
import threading
from datetime import datetime
from flask import Flask, render_template, jsonify, request, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder='.', template_folder='.')
CORS(app)

# Global variables for tracking deployments
deployment_logs = []
running_processes = {}

def log_message(message, level="INFO"):
    """Add a message to the deployment logs"""
    timestamp = datetime.now().isoformat()
    log_entry = {
        "timestamp": timestamp,
        "level": level,
        "message": message
    }
    deployment_logs.append(log_entry)
    
    # Keep only last 100 log entries
    if len(deployment_logs) > 100:
        deployment_logs.pop(0)
    
    print(f"[{timestamp}] [{level}] {message}")

def run_script_async(script_path, args, app_type, app_name):
    """Run a deployment script asynchronously"""
    try:
        log_message(f"Starting {app_type} deployment: {app_name}")
        
        # Build command
        cmd = [script_path] + args
        
        # Run the script
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=os.path.dirname(os.path.abspath(__file__)) + "/.."
        )
        
        # Store process reference
        process_key = f"{app_type}_{app_name}"
        running_processes[process_key] = process
        
        # Read output line by line
        for line in process.stdout:
            line = line.strip()
            if line:
                log_message(f"[{app_name}] {line}")
        
        # Wait for completion
        return_code = process.wait()
        
        # Remove from running processes
        if process_key in running_processes:
            del running_processes[process_key]
        
        if return_code == 0:
            log_message(f"Successfully deployed {app_name}", "SUCCESS")
        else:
            log_message(f"Failed to deploy {app_name} (exit code: {return_code})", "ERROR")
            
    except Exception as e:
        log_message(f"Error deploying {app_name}: {str(e)}", "ERROR")

@app.route('/')
def index():
    """Serve the main dashboard page"""
    return send_from_directory('.', 'index.html')

@app.route('/app.js')
def app_js():
    """Serve the JavaScript file"""
    return send_from_directory('.', 'app.js')

@app.route('/api/apps/<app_type>')
def get_apps(app_type):
    """Get list of available applications for a specific type"""
    try:
        apps = []
        base_path = os.path.dirname(os.path.abspath(__file__)) + "/.."
        
        if app_type == 'docker':
            # Find Docker Compose applications
            docker_path = os.path.join(base_path, 'docker-compose')
            if os.path.exists(docker_path):
                for item in os.listdir(docker_path):
                    compose_file = os.path.join(docker_path, item, 'compose.yaml')
                    if os.path.isfile(compose_file):
                        apps.append({
                            'name': item,
                            'status': get_docker_status(item),
                            'description': f'Docker Compose application: {item}',
                            'type': 'docker'
                        })
        
        elif app_type == 'kubernetes':
            # Find Kubernetes applications
            k8s_path = os.path.join(base_path, 'kubernetes')
            if os.path.exists(k8s_path):
                for item in os.listdir(k8s_path):
                    item_path = os.path.join(k8s_path, item)
                    if os.path.isdir(item_path):
                        helm_values = os.path.join(item_path, 'helm', 'values.yaml')
                        if os.path.isfile(helm_values):
                            apps.append({
                                'name': item,
                                'status': 'unknown',
                                'description': f'Kubernetes application: {item}',
                                'type': 'helm'
                            })
        
        elif app_type == 'ansible':
            # Find Ansible playbooks
            ansible_path = os.path.join(base_path, 'ansible')
            if os.path.exists(ansible_path):
                for root, dirs, files in os.walk(ansible_path):
                    for file in files:
                        if file.endswith('.yaml') and file != 'secrets.yaml':
                            rel_path = os.path.relpath(os.path.join(root, file), base_path)
                            name = os.path.splitext(file)[0]
                            apps.append({
                                'name': name,
                                'status': 'unknown',
                                'description': f'Ansible playbook: {name}',
                                'path': rel_path
                            })
        
        elif app_type == 'terraform':
            # Find Terraform configurations
            terraform_path = os.path.join(base_path, 'terraform')
            if os.path.exists(terraform_path):
                for item in os.listdir(terraform_path):
                    item_path = os.path.join(terraform_path, item)
                    if os.path.isdir(item_path):
                        # Check if directory contains .tf files
                        tf_files = [f for f in os.listdir(item_path) if f.endswith('.tf')]
                        if tf_files:
                            apps.append({
                                'name': item,
                                'status': 'unknown',
                                'description': f'Terraform configuration: {item}',
                                'type': 'terraform'
                            })
        
        return jsonify(apps)
        
    except Exception as e:
        log_message(f"Error getting {app_type} apps: {str(e)}", "ERROR")
        return jsonify({'error': str(e)}), 500

def get_docker_status(app_name):
    """Get the status of a Docker Compose application"""
    try:
        # Check if Docker is available
        subprocess.run(['docker', '--version'], check=True, capture_output=True)
        
        # Check if containers are running
        result = subprocess.run(
            ['docker', 'ps', '--format', '{{.Names}}'],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            running_containers = result.stdout.strip().split('\n')
            # Check if any container name contains the app name
            for container in running_containers:
                if app_name in container:
                    return 'running'
            return 'stopped'
        else:
            return 'unknown'
            
    except Exception:
        return 'unknown'

@app.route('/api/deploy/<app_type>/<app_name>', methods=['POST'])
def deploy_app(app_type, app_name):
    """Deploy an application"""
    try:
        base_path = os.path.dirname(os.path.abspath(__file__)) + "/.."
        
        # Determine which script to run
        script_map = {
            'docker': 'scripts/run-docker.sh',
            'kubernetes': 'scripts/run-k8s.sh',
            'ansible': 'scripts/run-ansible.sh',
            'terraform': 'scripts/run-terraform.sh'
        }
        
        if app_type not in script_map:
            return jsonify({'error': f'Unknown application type: {app_type}'}), 400
        
        script_path = os.path.join(base_path, script_map[app_type])
        
        if not os.path.isfile(script_path):
            return jsonify({'error': f'Script not found: {script_path}'}), 404
        
        # Make script executable
        os.chmod(script_path, 0o755)
        
        # Prepare arguments based on app type
        if app_type == 'ansible':
            # For Ansible, we need to find the full path to the playbook
            ansible_path = os.path.join(base_path, 'ansible')
            playbook_path = None
            
            for root, dirs, files in os.walk(ansible_path):
                for file in files:
                    if file.startswith(app_name) and file.endswith('.yaml'):
                        playbook_path = os.path.relpath(os.path.join(root, file), base_path)
                        break
                if playbook_path:
                    break
            
            if not playbook_path:
                return jsonify({'error': f'Playbook not found for: {app_name}'}), 404
            
            args = [playbook_path]
        else:
            args = [app_name]
        
        # Start deployment in background thread
        thread = threading.Thread(
            target=run_script_async,
            args=(script_path, args, app_type, app_name)
        )
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'message': f'Deployment started for {app_name}',
            'status': 'started'
        })
        
    except Exception as e:
        log_message(f"Error deploying {app_name}: {str(e)}", "ERROR")
        return jsonify({'error': str(e)}), 500

@app.route('/api/stop/<app_type>/<app_name>', methods=['POST'])
def stop_app(app_type, app_name):
    """Stop an application"""
    try:
        if app_type == 'docker':
            # Stop Docker Compose application
            base_path = os.path.dirname(os.path.abspath(__file__)) + "/.."
            compose_dir = os.path.join(base_path, 'docker-compose', app_name)
            
            if os.path.isdir(compose_dir):
                result = subprocess.run(
                    ['docker-compose', 'down'],
                    cwd=compose_dir,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0:
                    log_message(f"Stopped Docker application: {app_name}", "SUCCESS")
                    return jsonify({'message': f'Stopped {app_name}', 'status': 'stopped'})
                else:
                    log_message(f"Failed to stop {app_name}: {result.stderr}", "ERROR")
                    return jsonify({'error': result.stderr}), 500
            else:
                return jsonify({'error': f'Application directory not found: {app_name}'}), 404
        
        else:
            return jsonify({'error': f'Stop operation not implemented for {app_type}'}), 501
            
    except Exception as e:
        log_message(f"Error stopping {app_name}: {str(e)}", "ERROR")
        return jsonify({'error': str(e)}), 500

@app.route('/api/logs')
def get_logs():
    """Get deployment logs"""
    return jsonify(deployment_logs[-50:])  # Return last 50 log entries

@app.route('/api/status')
def get_status():
    """Get system status"""
    try:
        # Count running processes
        running_count = len(running_processes)
        
        # Get basic system info
        status = {
            'running_deployments': running_count,
            'total_logs': len(deployment_logs),
            'last_activity': deployment_logs[-1]['timestamp'] if deployment_logs else None,
            'processes': list(running_processes.keys())
        }
        
        return jsonify(status)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/system/<action>', methods=['POST'])
def system_action(action):
    """Handle system actions"""
    try:
        base_path = os.path.dirname(os.path.abspath(__file__)) + "/.."
        
        if action == 'check-dependencies':
            script_path = os.path.join(base_path, 'check-dependencies.sh')
            os.chmod(script_path, 0o755)
            
            result = subprocess.run([script_path], capture_output=True, text=True, cwd=base_path)
            
            return jsonify({
                'output': result.stdout,
                'error': result.stderr,
                'return_code': result.returncode
            })
        
        elif action == 'setup-env':
            script_path = os.path.join(base_path, 'scripts', 'setup-env-templates.sh')
            os.chmod(script_path, 0o755)
            
            result = subprocess.run([script_path], capture_output=True, text=True, cwd=base_path)
            
            return jsonify({
                'output': result.stdout,
                'error': result.stderr,
                'return_code': result.returncode
            })
        
        elif action == 'stop-all':
            # Stop all Docker containers
            result = subprocess.run(
                ['docker', 'stop', '$(docker ps -q)'],
                shell=True,
                capture_output=True,
                text=True
            )
            
            log_message("Stopped all Docker containers", "SUCCESS")
            
            return jsonify({
                'message': 'All services stopped',
                'output': result.stdout
            })
        
        else:
            return jsonify({'error': f'Unknown action: {action}'}), 400
            
    except Exception as e:
        log_message(f"Error executing system action {action}: {str(e)}", "ERROR")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Initialize logging
    log_message("Starting Turnkey Deployment Dashboard Server")
    
    # Make scripts executable
    base_path = os.path.dirname(os.path.abspath(__file__)) + "/.."
    scripts = [
        'check-dependencies.sh',
        'run.sh',
        'scripts/run-docker.sh',
        'scripts/run-ansible.sh',
        'scripts/run-k8s.sh',
        'scripts/run-terraform.sh',
        'scripts/setup-env-templates.sh'
    ]
    
    for script in scripts:
        script_path = os.path.join(base_path, script)
        if os.path.isfile(script_path):
            os.chmod(script_path, 0o755)
            log_message(f"Made {script} executable")
    
    # Start the server
    port = int(os.environ.get('PORT', 8000))
    log_message(f"Starting server on port {port}")
    
    app.run(host='0.0.0.0', port=port, debug=True)
