if [ $(git status --porcelain | wc -l) != "0" -o $(git log @{u}.. | wc -l) != "0" ];  then
  git add .
  cmt_msg=$(cat /tmp/up_details)
  git config --global user.email "pitchblackrecovery@gmail.com"
  git config --global user.name "pbrp-bot"
  git commit -m "PBRP: Auto-Update Tools$cmt_msg"
  git push
else
  echo "Already updated"
fi
