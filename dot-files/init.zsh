
# This one needs to go in the ~/.zshrc
# source ~/vault/git/dot-files/init.zsh

# Dot files zsh
for file in ~/vault/git/dot-files/dot-files/zsh/common/*.zsh; do
  source "$file"
done

for file in ~/vault/git/dot-files/dot-files/zsh/work/*.zsh; do
  source "$file"
done

for file in ~/vault/git/dot-files/dot-files/zsh/personal/*.zsh; do
  source "$file"
done

# Functions
for file in ~/vault/git/dot-files/dot-files/scripts/common/*.sh; do
  source "$file"
done

for file in ~/vault/git/dot-files/dot-files/scripts/work/*.sh; do
  source "$file"
done
