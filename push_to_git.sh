#!/bin/bash

# Configuration
BRANCH_NAME=$(git branch --show-current)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "=============================================="
echo "Preparing to push changes to branch: $BRANCH_NAME"
echo "Timestamp: $TIMESTAMP"
echo "=============================================="

# 1. Add Backend Code
echo "Adding Backend Code (paw_api)..."
git add paw_api/
# Ensure __pycache__ is ignored via .gitignore usually, but we can specifically exclude if needed.
# Typically git add folder/ adds valid files.

# 2. Add Requirements
echo "Adding dependencies..."
git add requirements.txt

# 3. Add Frontend Code
echo "Adding Frontend Code..."
git add pet1.html pet3.js pet2.css

# 4. Add SQL Scripts (Schema definitions)
echo "Adding SQL Schemas..."
git add paw_rescue_data1/

# 5. Commit
echo "Committing changes..."
COMMIT_MSG="Feat: Complete backend implementation and UI fixes

- Implemented FastAPI backend (paw_api) with routers for Auth, Pets, Donations, Requests, etc.
- Added database connection logic (asyncpg).
- Refactored frontend (pet3.js) to use API instead of simulation.
- Fixed UI bugs: login/register, pet details modal, foundation flow.
- Added foundation pet registration with proper DB links.
- Fixed date format issues and schema mismatches (id_origen, vacunas).
- Verified full flow: Login -> Register Pet -> View Details -> Adopt.
"

git commit -m "$COMMIT_MSG"

# 6. Push
echo "Pushing to origin $BRANCH_NAME..."
git push origin "$BRANCH_NAME"

echo "=============================================="
echo "                     DONE                     "
echo "=============================================="
