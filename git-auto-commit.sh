#!/bin/bash

MODEL_NAME="tavernari/git-commit-message:pro"

# 1. Git repository yoxdursa init et
if [ ! -d ".git" ]; then
  echo "No git repository found. Initializing git..."
  git init
fi

# 2. Origin remote yoxdursa terminaldan soruş və əlavə et
if ! git remote get-url origin &>/dev/null; then
  read -p "No remote 'origin' found. Enter remote URL: " REMOTE_URL
  git remote add origin "$REMOTE_URL"
  echo "Remote 'origin' set to $REMOTE_URL"
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

# 7. Staged diff-i götür
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

# 12. Avtomatik push et
git push -u origin "$current_branch"
echo "Push done to branch '$current_branch'."

# 13. AI modelini stop et
echo "Stopping AI model..."
ollama stop $MODEL_NAME
echo "AI model stopped."
