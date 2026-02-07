# Secrets Vault

This directory contains templates for secrets management. **Never store actual secrets here.**

## Usage

### Option 1: 1Password CLI (Recommended)

```bash
# Sign in to 1Password
op signin

# Inject secrets into environment
op run --env-file=templates/development.env.template -- your-command
```

### Option 2: Local ~/.secrets file

```bash
# Copy template to home directory
cp templates/development.env.template ~/.secrets

# Edit with real values
nano ~/.secrets

# Set secure permissions
chmod 600 ~/.secrets
```

### Option 3: macOS Keychain

```bash
# Store a secret
security add-generic-password -s "my-app" -a "API_KEY" -w "secret-value"

# Retrieve a secret
security find-generic-password -s "my-app" -a "API_KEY" -w
```

## Templates

| Template | Purpose |
|----------|---------|
| `development.env.template` | Local development secrets |

## Security Rules

1. **Never commit real secrets** - Templates only
2. **Use 600 permissions** - `chmod 600 ~/.secrets`
3. **Rotate on exposure** - Immediately
4. **Prefer 1Password CLI** - Avoids file-based secrets
