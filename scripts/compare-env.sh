#!/usr/bin/env bash
# Script pour comparer l'environnement entre Docker et VM

echo "=== ENVIRONMENT COMPARISON ==="
echo ""
echo "--- Python & Pip ---"
python3 --version
pip3 --version
which python3
which pip3
ls -la $(which python3) 2>/dev/null || true
ls -la $(which pip3) 2>/dev/null || true

echo ""
echo "--- Python paths ---"
python3 -c "import sys; print('\n'.join(sys.path))"

echo ""
echo "--- Pip externally-managed ---"
if [ -f /usr/lib/python*/EXTERNALLY-MANAGED ]; then
    echo "EXTERNALLY-MANAGED file exists:"
    ls -la /usr/lib/python*/EXTERNALLY-MANAGED
    cat /usr/lib/python*/EXTERNALLY-MANAGED
else
    echo "No EXTERNALLY-MANAGED file found"
fi

echo ""
echo "--- Available pip install methods ---"
pip3 --help | grep -A 5 "install"

echo ""
echo "--- Test pip install (dry-run) ---"
pip3 install --dry-run --user setuptools 2>&1 | head -20

echo ""
echo "--- Git configuration ---"
git config --global --list 2>/dev/null || echo "No global git config"
ls -la ~/.gitconfig 2>/dev/null || echo "No .gitconfig in HOME"
sudo ls -la /root/.gitconfig 2>/dev/null || echo "No .gitconfig for root"

echo ""
echo "--- WordOps check ---"
which wo 2>/dev/null || echo "wo command not found"
pip3 list | grep -i wordops || echo "WordOps not in pip list"
pip3 show wordops 2>/dev/null || echo "WordOps not installed via pip"

echo ""
echo "--- apt sources ---"
cat /etc/apt/sources.list
ls -la /etc/apt/sources.list.d/

echo ""
echo "=== END COMPARISON ==="
