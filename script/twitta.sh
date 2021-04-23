#!/bin/bash

### descrizione ###
#
# Uno script che pubblicherà ogni 4 giorni un tweet con uno degli interventi del raduno
#
### descrizione ###

set -x
set -e
set -u
set -o pipefail

git pull

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $(hostname) == "DESKTOP-7NVNDNF" ]]; then
  source "$folder"/.config
fi

# se il file con la lista dei tweet non esiste, crealo
if [ ! -f "$folder"/toTweet.csv ]; then
  mlr --csv filter '$to_tweet==1' then cut -f id,tweet "$folder"/lista.csv >"$folder"/toTweet.csv
fi

# conta quante righe ci sono da tweettare
completed=$(wc <"$folder"/toTweet.csv -l)

# se sono minori o uguali a 1, esci
if [ "$completed" -le 1 ]; then
  exit 1
fi

#estrai il testo da twittare
testo=$(mlr --c2n filter 'NR==1' then cut -f tweet "$folder"/toTweet.csv)

# twitta
echo "$testo"
twurl -c "$apiKey" -s "$apiKeySecret" -a "$token" -S "$secret" "/1.1/statuses/update.json" -d 'status='"$testo"'' >"$folder"/log.json

# leggi se il tweet è andato a buon fine
ok=$(jq <"$folder"/log.json -r '.retweet_count')

# se andato a buon fine, rimuovi la riga twittata
if [ "$ok" -ge 0 ]; then
  # rimuovi prima riga
  mlr -I --csv filter -x 'NR==1' "$folder"/toTweet.csv
fi
