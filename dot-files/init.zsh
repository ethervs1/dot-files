
# Dot files zsh
for file in ~/git/dot-files/zsh/*.zsh; do
  source "$file"
done

# Functions
for file in ~/git/dot-files/scripts/*.sh; do
  source "$file"
done
