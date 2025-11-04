
# How to Update Your Project on GitHub

This is a step-by-step guide for committing and pushing your local changes to the main branch on GitHub.

---

## 🧩 Step 1: Check Status

See which files you've changed or added.

```bash
git status
```

---

## 🧰 Step 2: Add All Files

Add all new and changed files to the "staging area" to prepare them for a commit.

```bash
git add .
```

---

## 💬 Step 3: Commit the Changes

Save your changes as a "commit" with a short, descriptive message.

```bash
git commit -m "Your descriptive message here"
```

---

## 🔄 Step 4: Pull Latest Remote Changes

Important: Before you push, always sync with the remote repository (GitHub) first. The `--rebase` flag pulls down any changes from GitHub and places your new commits on top of them, keeping a clean history.

```bash
git pull origin main --rebase
```

---

## ⚠️ Step 5: Handle Conflicts (If they happen)

If Step 4 reports a "CONFLICT," Git needs your help.

Open the conflicted file(s) in your code editor. Look for the conflict markers:

```text
<<<<<<< HEAD
(Your local changes are here)
=======
(The remote changes are here)
>>>>>>> origin/main
```

Delete all the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) and edit the file to keep the code exactly as you want it.

Once all conflicts are fixed, save the files and run these commands to finish the rebase:

```bash
git add .
git rebase --continue
```

---

## 🚀 Step 6: Push Your Updates to GitHub

Once all your changes are committed and you've successfully synced (and rebased), you can now push your updates to GitHub.

```bash
git push origin main
```
