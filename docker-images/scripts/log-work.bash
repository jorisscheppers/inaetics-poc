x=1
echo 'CURLing to '"$IG_ENDPOINT"
while true
do
  DATE=$(date +"%Y-%m-%dT%TZ")
  curl -X POST 'http://'"$IG_ENDPOINT"'/ig/rest/ig-document-service/collection/records' -H "accept: application/json" -H "Content-Type: application/json" -d "{\"time\":\"$DATE\",\"value\":\"Iteration: $x\"}" -H "Authorization: Bearer ozZNC7gHChGzOaIrI1KZTA=="
  x=$(( $x + 1 ))
  echo 
  sleep 10s
done