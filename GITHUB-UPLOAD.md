# How to Upload This to GitHub

Personal reference for getting this repo live on GitHub.

---

## Prerequisites

Make sure you're logged into GitHub via the CLI (only need to do this once):

```bash
gh auth login
```

Choose **GitHub.com → HTTPS → Login with a web browser** and follow the prompts.

---

## First-Time Upload (Do This Once)

```bash
# 1. Navigate to the repo directory
cd ~/claude/omarchy-customizations

# 2. Initialize git
git init

# 3. Stage all files
git add .

# 4. Initial commit
git commit -m "Initial commit: Omarchy Linux customizations"

# 5. Create the public GitHub repo and push in one step
gh repo create omarchy-customizations \
  --public \
  --source=. \
  --push \
  --description "Custom scripts and configs for Omarchy Linux: dual VPN in waybar, NAS mounting, startup sounds, keybind cheat sheets, and more"
```

Done. Your repo will be live at:
`https://github.com/YOUR_GITHUB_USERNAME/omarchy-customizations`

---

## Pushing Future Updates

After the initial upload, any time you update files:

```bash
cd ~/claude/omarchy-customizations

# Stage changed files
git add .

# Commit with a description of what changed
git commit -m "describe what you changed"

# Push to GitHub
git push
```

---

## Quick Reference: Useful Git Commands

```bash
# See what files have changed (not yet committed)
git status

# See what actually changed inside files
git diff

# See commit history
git log --oneline

# Undo all uncommitted changes (careful — destructive)
git checkout .
```

---

## If You Need to Start Over

If something goes wrong with git init and you want to reset:

```bash
cd ~/claude/omarchy-customizations
rm -rf .git
# Then redo the First-Time Upload steps above
```
