#!/bin/bash

MODEL_NAME="tavernari/git-commit-message:pro"

# 1. Hazır branch-i götür
current_branch=$(git symbolic-ref --short HEAD)
if [[ -z "$current_branch" ]]; then
  echo "Error: Not on a valid branch."
  exit 1
fi

# 2. Origin olub olmadığını yoxla
if ! git ls-remote --exit-code origin &>/dev/null; then
  echo "Warning: Remote 'origin' not found. Push will be skipped."
  remote_exists=false
else
  remote_exists=true
fi

# 3. Branch adından prefix və issue ID təyin et
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

# 4. Bütün dəyişiklikləri stage et
git add .

# 5. Staged dəyişiklikləri yoxla
if git diff --cached --quiet; then
  echo "No staged changes to commit."
  exit 0
fi

# 6. Staged diff-i götür
diff_content=$(git diff --cached)

# 7. AI modelini run et və commit mesajını al
echo "Generating commit message using AI..."
commit_msg=$(echo "$diff_content" | ollama run $MODEL_NAME)
echo "AI commit message generated."

# 8. Commit mesajına avtomatik prefix və issue ID əlavə et
if [[ -n "$prefix" ]]; then
  commit_msg="$prefix $issue_id $commit_msg"
fi

# 9. Commit mesajını ekrana çıxar
echo "---------------------------------"
echo "$commit_msg"
echo "---------------------------------"

# 10. Avtomatik commit et
git commit -F <(echo "$commit_msg")
echo "Commit done."

# 11. Avtomatik push et əgər origin varsa
if $remote_exists; then
  git push origin "$current_branch"
  echo "Push done to branch '$current_branch'."
else
  echo "No remote 'origin' found. Push skipped."
fi

# 12. AI modelini stop et
echo "Stopping AI model..."
ollama stop $MODEL_NAME
echo "AI model stopped."
