
# Dot files zsh
for file in ~/dot-files/zsh/*.zsh; do
  source "$file"
done

# Functions
for file in ~/dot-files/scripts/*.sh; do
  source "$file"
done
