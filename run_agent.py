#!/usr/bin/env python3
import os
import sys
import json
import time
from codegen.agents.agent import Agent

def set_output(name, value):
    """Set an output parameter for GitHub Actions."""
    with open(os.environ.get('GITHUB_OUTPUT', '/dev/null'), 'a') as f:
        if isinstance(value, (dict, list)):
            value = json.dumps(value)
        f.write(f"{name}={value}\n")

def main():
    # Get inputs from environment variables
    org_id = os.environ.get('INPUT_ORG_ID')
    token = os.environ.get('INPUT_TOKEN')
    prompt = os.environ.get('INPUT_PROMPT')
    base_url = os.environ.get('INPUT_BASE_URL')
    wait_for_completion = os.environ.get('INPUT_WAIT_FOR_COMPLETION', 'true').lower() == 'true'
    timeout_seconds = int(os.environ.get('INPUT_TIMEOUT_SECONDS', '300'))
    
    # Validate required inputs
    if not org_id:
        print("Error: Organization ID is required")
        sys.exit(1)
    if not token:
        print("Error: API token is required")
        sys.exit(1)
    if not prompt:
        print("Error: Prompt is required")
        sys.exit(1)
    
    # Initialize the Agent
    agent_kwargs = {
        'org_id': org_id,
        'token': token,
    }
    
    if base_url:
        agent_kwargs['base_url'] = base_url
    
    try:
        agent = Agent(**agent_kwargs)
        
        # Run the agent with the provided prompt
        print(f"Running Codegen agent with prompt: {prompt}")
        task = agent.run(prompt=prompt)
        
        # Set the task ID as output
        task_id = task.id if hasattr(task, 'id') else str(task)
        set_output('task_id', task_id)
        set_output('status', task.status)
        
        print(f"Task created with ID: {task_id}")
        print(f"Initial status: {task.status}")
        
        # Wait for completion if requested
        if wait_for_completion:
            start_time = time.time()
            while task.status not in ['completed', 'failed', 'error'] and (time.time() - start_time) < timeout_seconds:
                print(f"Waiting for task completion... Current status: {task.status}")
                time.sleep(10)  # Check every 10 seconds
                task.refresh()
            
            # Final status after waiting
            print(f"Final status: {task.status}")
            set_output('status', task.status)
            
            # If completed, set the result
            if task.status == 'completed':
                result = task.result
                print(f"Task completed with result: {result}")
                set_output('result', result)
            elif task.status == 'failed' or task.status == 'error':
                print(f"Task failed or errored")
                sys.exit(1)
            else:
                print(f"Task did not complete within the timeout period")
                sys.exit(1)
        
    except Exception as e:
        print(f"Error running Codegen agent: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()

