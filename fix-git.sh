#!/bin/bash
cat > /root/.gitconfig << 'EOF'
[user]
	name = WordOps User
	email = wordops@localhost
[safe]
	directory = *
EOF
