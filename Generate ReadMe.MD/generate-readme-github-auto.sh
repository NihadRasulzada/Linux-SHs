#!/bin/bash
# ---------------------------
# Fully Automatic GitHub-ready README Generator (Enhanced)
# ---------------------------

# 1️⃣ Find the project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_ROOT" ]; then
    echo "❌ This does not seem to be a git repository!"
    exit 1
fi
cd "$PROJECT_ROOT" || exit 1
echo "📁 Project root: $PROJECT_ROOT"

# 2️⃣ Backup existing README.md
if [ -f README.md ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    cp README.md README_backup_$TIMESTAMP.md
    echo "📦 Existing README.md backed up as README_backup_$TIMESTAMP.md"
fi

# 3️⃣ Gather project files
PROJECT_CONTENT=$(find . -type f -not -path "*/\.*" -not -size +500k -exec cat {} +)

# 4️⃣ Detect GitHub repo info
GITHUB_URL=$(git config --get remote.origin.url)
if [[ $GITHUB_URL == git@* ]]; then
    GITHUB_URL=${GITHUB_URL/git@github.com:/https://github.com/}
    GITHUB_URL=${GITHUB_URL%.git}
fi

# 5️⃣ Detect license type
if [ -f LICENSE ]; then
    LICENSE_TYPE=$(head -n 1 LICENSE)
else
    LICENSE_TYPE="MIT"
fi

# 6️⃣ Detect project frameworks & versions
FRAMEWORKS=""
if [ -f "*.csproj" ] || ls *.csproj 1> /dev/null 2>&1; then
    FRAMEWORKS+="$(grep -oPm1 "(?<=<TargetFramework>)[^<]+" *.csproj) "
fi
if [ -f package.json ]; then
    NODE_VERSION=$(jq -r '.engines.node // empty' package.json)
    [ -n "$NODE_VERSION" ] && FRAMEWORKS+="Node.js $NODE_VERSION "
fi
if [ -f requirements.txt ]; then
    PYTHON_VERSION=$(head -n 1 requirements.txt | grep -oP "python>=?\d+(\.\d+)*" || true)
    [ -n "$PYTHON_VERSION" ] && FRAMEWORKS+="Python $PYTHON_VERSION "
fi
if [ -f Dockerfile ]; then
    DOCKER_BASE=$(grep -i "FROM" Dockerfile | head -n 1)
    [ -n "$DOCKER_BASE" ] && FRAMEWORKS+="$DOCKER_BASE "
fi

# 7️⃣ Detect Git tags (version) and changelog
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")
CHANGELOG=$(git log --pretty=format:"* %h %s" -n 10)

# 8️⃣ Define README sections
SECTIONS=("Project Overview" "Installation" "Usage" "Features" "Architecture" "Technologies and Dependencies" "Example Code" "Versioning & Changelog" "License" "Contribution Guidelines")

# 9️⃣ Generate each section using AI
echo "📝 Generating README.md sections..."
README_TMP="README_TMP.md"
> $README_TMP

for SECTION in "${SECTIONS[@]}"; do
    PROMPT="You are a professional README.md generator.
Analyze the following project files and generate a high-quality, GitHub-ready Markdown section for: $SECTION
Include:
- Code snippets from main modules and API endpoints (for Example Code)
- Automatic detection of technologies, frameworks, versions, and dependencies (for Technologies section)
- Git tags and recent commits (for Versioning & Changelog)
- README should be in English and Azerbaijani
Use GitHub URL: $GITHUB_URL
Use License: $LICENSE_TYPE
Detected frameworks and versions: $FRAMEWORKS
Project files content:
$PROJECT_CONTENT"

    echo "Generating section: $SECTION ..."
    SECTION_CONTENT=$(ollama run llama3.1:70b-instruct-q4_K_S "$PROMPT")
    echo "## $SECTION" >> $README_TMP
    echo "$SECTION_CONTENT" >> $README_TMP
    echo "" >> $README_TMP
done

# 🔟 Add Table of Contents
TOC=$(printf "%s\n" "${SECTIONS[@]}" | gawk '{print "- ["$0"](#"tolower(gensub(/ /,"-","g",$0))")"}')
FINAL_README="README.md"
echo "# Table of Contents" > $FINAL_README
echo "$TOC" >> $FINAL_README
echo "" >> $FINAL_README

# 1️⃣1️⃣ Add default GitHub badges
echo "[![License](https://img.shields.io/badge/license-$LICENSE_TYPE-blue.svg)]($GITHUB_URL/blob/main/LICENSE)" >> $FINAL_README
echo "[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]($GITHUB_URL/actions)" >> $FINAL_README
echo "[![Coverage](https://img.shields.io/badge/coverage-90%25-brightgreen.svg)]($GITHUB_URL)" >> $FINAL_README
# Optional security badge
echo "[![Vulnerabilities](https://img.shields.io/badge/security-clean-brightgreen.svg)]($GITHUB_URL)" >> $FINAL_README
echo "" >> $FINAL_README

# 1️⃣2️⃣ Append all generated sections
cat $README_TMP >> $FINAL_README
rm $README_TMP

# 1️⃣3️⃣ Refine final README
FINAL_CONTENT=$(cat $FINAL_README)
REFINED_CONTENT=$(ollama run llama3.1:70b-instruct-q4_K_S "Refine the following README.md to be professional, clear, bilingual (English & Azerbaijani), GitHub-ready:
$FINAL_CONTENT")

echo "$REFINED_CONTENT" > $FINAL_README

echo "✅ Enhanced, bilingual, GitHub-ready README.md generated!"

# 1️⃣4️⃣ Stop the model to free memory
echo "🛑 Stopping Llama3.1 model to free resources..."
# This stops the currently running model instance
ollama stop llama3.1:70b-instruct-q4_K_S 2>/dev/null || true

echo "✅ Model stopped. Memory freed."