🧩 Step 2: Check the Current Git Status

See which files are changed or new:

    git status

🧰 Step 3: Add All Files to Git

Add everything (new + changed files):

    git add .

💬 Step 4: Commit the Changes

Give your update a short message:

    git commit -m "Updated all project files"

🔄 Step 5: Pull Latest Remote Changes (important)

Before pushing, always sync with GitHub first:

    git pull origin main --rebase

Fix the conflict markers:

<<<<<<< HEAD
your local changes
=======
remote changes
>>>>>>> origin/main


Then run:

    git add .
    git rebase --continue

🚀 Step 6: Push Your Updates to GitHub

Now push your new commits:

git push origin main