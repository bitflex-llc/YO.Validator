---
name: Bug Report
about: Create a report to help us improve the YO Network validator setup
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description

### Summary
<!-- A clear and concise description of what the bug is -->

### Expected Behavior
<!-- What you expected to happen -->

### Actual Behavior
<!-- What actually happened -->

### Impact
<!-- How does this bug affect you? -->
- [ ] Prevents validator from starting
- [ ] Causes sync issues
- [ ] Performance degradation
- [ ] Documentation is incorrect
- [ ] Security concern
- [ ] Other: <!-- specify -->

## 🔍 Reproduction Steps

### Prerequisites
<!-- What needs to be set up before reproducing -->
- Operating System: <!-- e.g., Ubuntu 22.04 -->
- Docker version: <!-- e.g., 24.0.6 -->
- Docker Compose version: <!-- e.g., v2.21.0 -->

### Steps to Reproduce
1. <!-- First step -->
2. <!-- Second step -->
3. <!-- Third step -->
4. <!-- See error -->

### Minimal Reproduction Case
<!-- If possible, provide the smallest configuration that reproduces the issue -->
```bash
# Commands that reproduce the issue
```

## 📋 Environment Information

### System Information
```bash
# Please provide output of these commands:
uname -a
lsb_release -a
docker --version
docker compose version
```

### Validator Configuration
```yaml
# Please share relevant parts of your docker-compose.yml (remove sensitive data)
```

### Network Information
```bash
# If network-related, provide:
ip addr show
docker network ls
```

## 📊 Logs and Evidence

### Error Messages
<!-- Paste any error messages here -->
```
Error text here
```

### Container Logs
```bash
# Output of: docker compose logs besu-validator --tail=50
```

### System Logs
```bash
# If relevant, output of: journalctl -u docker.service --tail=20
```

### Screenshots
<!-- If applicable, add screenshots to help explain the problem -->

## 🧪 Debugging Attempted

### What I've Tried
<!-- List the steps you've already taken to debug the issue -->
- [ ] Restarted containers: `docker compose restart`
- [ ] Checked logs: `docker compose logs`
- [ ] Verified configuration files
- [ ] Checked system resources
- [ ] Reviewed documentation
- [ ] Searched existing issues

### Workaround Found
<!-- If you found a temporary workaround, describe it -->
- [ ] No workaround found
- [ ] Temporary workaround: <!-- describe -->

## 📝 Additional Context

### Related Issues
<!-- Link any related issues -->
- Related to #(issue number)
- Similar to #(issue number)

### Configuration Details
<!-- Any specific configuration that might be relevant -->
- Using custom genesis.json: <!-- Yes/No -->
- Modified static-nodes.json: <!-- Yes/No -->
- Using custom ports: <!-- Yes/No -->
- Behind proxy/firewall: <!-- Yes/No -->

### Timeline
<!-- When did this start happening? -->
- [ ] Always happened
- [ ] Started after update
- [ ] Started after configuration change
- [ ] Intermittent issue
- [ ] First time setup

## 🔒 Security Considerations

<!-- If this bug has security implications -->
- [ ] This bug does not involve security issues
- [ ] This bug may have security implications
- [ ] This bug exposes sensitive information
- [ ] This bug affects authentication/authorization

---

## For Maintainers

### Triage Information
- [ ] Bug confirmed
- [ ] Needs more information
- [ ] Cannot reproduce
- [ ] Duplicate of existing issue
- [ ] Not a bug (expected behavior)

### Priority
- [ ] Critical (validator cannot start)
- [ ] High (major functionality broken)
- [ ] Medium (minor functionality issue)
- [ ] Low (cosmetic or documentation)

### Component
- [ ] Setup script
- [ ] Docker configuration
- [ ] Besu configuration
- [ ] Networking
- [ ] Monitoring
- [ ] Documentation
- [ ] Security
