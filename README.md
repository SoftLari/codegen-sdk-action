# Codegen SDK Action

This GitHub Action allows you to easily run the Codegen SDK agent in your workflows, enabling AI-powered code generation and analysis directly in your CI/CD pipeline.

## Features

- Run Codegen agent with a custom prompt
- Wait for task completion or run asynchronously
- Control whether to wait for push operations or use "fire and forget"
- Get task results directly in your workflow

## Usage

### Basic Example

```yaml
name: Run Codegen Agent

on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 'Prompt for Codegen agent'
        required: true
        type: string

jobs:
  run-codegen:
    runs-on: ubuntu-latest
    steps:
      - name: Run Codegen Agent
        uses: SoftLari/codegen-sdk-action@main
        with:
          org_id: ${{ secrets.CODEGEN_ORG_ID }}
          token: ${{ secrets.CODEGEN_API_TOKEN }}
          prompt: ${{ github.event.inputs.prompt }}
```

### Advanced Example

```yaml
name: Run Codegen Agent with Options

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  analyze-code:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Run Codegen Agent
        id: codegen
        uses: SoftLari/codegen-sdk-action@main
        with:
          org_id: ${{ secrets.CODEGEN_ORG_ID }}
          token: ${{ secrets.CODEGEN_API_TOKEN }}
          prompt: "Review the changes in this PR and suggest improvements"
          wait_for_completion: 'true'
          wait_for_push: 'false'
          timeout_seconds: '600'
          
      - name: Use Codegen Results
        if: steps.codegen.outputs.status == 'completed'
        run: |
          echo "Codegen task completed with result: ${{ steps.codegen.outputs.result }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `org_id` | Organization ID for Codegen service | Yes | - |
| `token` | API token for Codegen service | Yes | - |
| `prompt` | Prompt to send to Codegen agent | Yes | - |
| `base_url` | Base URL for Codegen API (optional) | No | - |
| `wait_for_completion` | Whether to wait for the task to complete | No | `true` |
| `wait_for_push` | Whether to wait for push operations to complete or use "fire and forget" | No | `true` |
| `timeout_seconds` | Maximum time to wait for completion in seconds | No | `300` |

## Outputs

| Output | Description |
|--------|-------------|
| `task_id` | ID of the created task |
| `status` | Status of the task |
| `result` | Result of the task (if completed) |

## Getting Started

1. Get your Codegen Organization ID and API Token from [codegen.com/developer](https://codegen.com/developer)
2. Add these as secrets in your GitHub repository
3. Create a workflow file using one of the examples above
4. Run the workflow and enjoy AI-powered code assistance!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
