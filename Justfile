set dotenv-load := false
set shell := ["bash", "-uc"]

# Default recipe: list all available commands
default:
    @just --list

# Initialize pre-commit hooks and local git environment
init:
    @echo "==> Installing pre-commit git hooks..."
    @if command -v pre-commit >/dev/null 2>&1; then \
        pre-commit install; \
        echo "✓ Git pre-commit hooks successfully installed."; \
    else \
        echo "✗ pre-commit is not found in PATH. Ensure you are inside the DevContainer."; \
    fi

# Run pre-commit checks and linters against all files in repository
lint:
    @echo "==> Running pre-commit validation suite..."
    pre-commit run --all-files

# Encrypt an unencrypted YAML secret file using AES-256
vault-encrypt FILE:
    @echo "==> Encrypting {{FILE}}..."
    ansible-vault encrypt "{{FILE}}"

# Decrypt an encrypted YAML file to plaintext
vault-decrypt FILE:
    @echo "==> Decrypting {{FILE}}..."
    ansible-vault decrypt "{{FILE}}"

# View an encrypted vault file in the terminal
vault-view FILE:
    ansible-vault view "{{FILE}}"

# Edit an encrypted vault file in-place using default editor
vault-edit FILE:
    ansible-vault edit "{{FILE}}"

# Verify syntax of all Ansible roles and playbooks
ansible-check:
    @echo "==> Performing Ansible playbook syntax check..."
    ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --syntax-check

# Execute playbook convergence via ansible-playbook stdout
ansible-apply:
    @echo "==> Executing platform convergence..."
    ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml

# Launch interactive Red Hat Ansible Navigator TUI dashboard
ansible-tui:
    @echo "==> Launching Ansible Navigator TUI..."
    ansible-navigator run ansible/playbooks/site.yml
