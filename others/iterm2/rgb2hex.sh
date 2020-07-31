curl -fsSL -O https://raw.githubusercontent.com/jonathaneunice/iterm2-tab-set/master/csscolors.js
while read -r i; do
  rgb=$(grep -E "\s$i:" csscolors.js | sed -re "s:.*\[(.*)\],?$:\1:";)
  hexc=$(for c in $(echo ${rgb} | sed -re 's:,::g'); do printf '%x' $c; done)
  echo -e """ $i :\t$rgb :\t$hexc """
  # echo "$hexc" >> ~/.marslo/.it2color
done < ~/.marslo/.colors
