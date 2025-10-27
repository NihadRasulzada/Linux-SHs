#!/bin/bash

MODEL_NAME="tavernari/git-commit-message:pro"

# Script-in işlədiyi hazır path
REPO_PATH=$(pwd)
echo "Running git-auto in path: $REPO_PATH"

# 1. Git repository yoxdursa soruş
if [ ! -d "$REPO_PATH/.git" ]; then
  read -p "No git repository found. Do you want to initialize git here? (y/n): " init_confirm
  if [[ "$init_confirm" == "y" || "$init_confirm" == "Y" ]]; then
    git init
    echo "Git initialized."
  else
    echo "Git init skipped. Exiting."
    exit 0
  fi
fi

# 2. Origin remote yoxdursa terminaldan soruş və əlavə et
if ! git remote get-url origin &>/dev/null; then
  read -p "No remote 'origin' found. Enter remote URL (or leave empty to skip): " REMOTE_URL
  if [[ -n "$REMOTE_URL" ]]; then
    git remote add origin "$REMOTE_URL"
    echo "Remote 'origin' set to $REMOTE_URL"
  else
    echo "Skipping remote setup."
  fi
fi

# 3. Bütün dəyişiklikləri stage et
git add .

# 4. Staged dəyişiklikləri yoxla
if git diff --cached --quiet; then
  echo "No staged changes to commit."
  exit 0
fi

# 5. Hazır branch-i götür, əgər yoxdursa 'master' təyin et
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
if [[ "$current_branch" == "master" && ! $(git rev-parse --verify master 2>/dev/null) ]]; then
  git checkout -b master
fi

# 6. Branch adından prefix və issue ID təyin et
prefix=""
issue_id=""
if [[ "$current_branch" =~ ^feature/([0-9]+)- ]]; then
  prefix="[Feature]"
  issue_id="[#$BASH_REMATCH]"
elif [[ "$current_branch" =~ ^bugfix/([0-9]+)- ]]; then
  prefix="[Bugfix]"
  issue_id="[#$BASH_REMATCH]"
elif [[ "$current_branch" =~ ^docs/([0-9]+)- ]]; then
  prefix="[Docs]"
  issue_id="[#$BASH_REMATCH]"
fi

# 7. Staged diff-i götür (bütün dəyişikliklər göndərilir)
diff_content=$(git diff --cached)

# 8. AI modelini run et və commit mesajını al
echo "Generating commit message using AI..."
commit_msg=$(echo "$diff_content" | ollama run $MODEL_NAME)
echo "AI commit message generated."

# 9. Commit mesajına avtomatik prefix və issue ID əlavə et
if [[ -n "$prefix" ]]; then
  commit_msg="$prefix $issue_id $commit_msg"
fi

# 10. Commit mesajını ekrana çıxar
echo "---------------------------------"
echo "$commit_msg"
echo "---------------------------------"

# 11. Avtomatik commit et
git commit -F <(echo "$commit_msg")
echo "Commit done."

# 12. Avtomatik push et əgər origin varsa
if git remote get-url origin &>/dev/null; then
  git push -u origin "$current_branch"
  echo "Push done to branch '$current_branch'."
else
  echo "No remote 'origin' found. Push skipped."
fi

# 13. AI modelini stop et
echo "Stopping AI model..."
ollama stop $MODEL_NAME
echo "AI model stopped."
