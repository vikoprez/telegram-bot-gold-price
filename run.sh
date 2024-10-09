#!/bin/bash

source .env
URL="http://kimphatminhkhoi.coimedia.com/"

send_telegram_message() {
  local message="$1"

  while IFS= read -r chat_id; do
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      -d chat_id="$chat_id" \
      -d text="$message" \
      -d parse_mode="Markdown" >/dev/null
  done <"$CHAT_IDS_FILE"
}

if [[ ! -f "$CHAT_IDS_FILE" ]]; then
  echo "No chat_ids.txt file found. Please add some chat IDs."
  exit 1
fi

fetch_gold_prices() {
  page_content=$(curl -s "$URL")

  nhan_tron_mua=$(echo "$page_content" | grep -A3 'NHẪN TRÒN' | grep -oP '(?<=<td>)[^<]+(?=</td>)' | sed -n 3p)
  nhan_tron_ban=$(echo "$page_content" | grep -A3 'NHẪN TRÒN' | grep -oP '(?<=<td>)[^<]+(?=</td>)' | sed -n 4p)

  cty_kpmk_mua=$(echo "$page_content" | grep -A3 'CTY - KPMK' | grep -oP '(?<=<td>)[^<]+(?=</td>)' | sed -n 3p)
  cty_kpmk_ban=$(echo "$page_content" | grep -A3 'CTY - KPMK' | grep -oP '(?<=<td>)[^<]+(?=</td>)' | sed -n 4p)

  echo "{\"Vàng 9999\": {\"MUA VÀO\": \"$nhan_tron_mua\", \"BÁN RA\": \"$nhan_tron_ban\"}, \"Vàng CTY\": {\"MUA VÀO\": \"$cty_kpmk_mua\", \"BÁN RA\": \"$cty_kpmk_ban\"}}"
}

load_previous_prices() {
  if [[ -f "$DATA_FILE" ]]; then
    cat "$DATA_FILE"
  else
    echo "{}"
  fi
}

save_current_prices() {
  local prices="$1"
  echo "$prices" >"$DATA_FILE"
}

compare_prices() {
  local old_prices="$1"
  local new_prices="$2"

  local changes=""
  local keys=("Vàng 9999" "Vàng CTY")
  local price_types=("MUA VÀO" "BÁN RA")

  for key in "${keys[@]}"; do
    local key_changes=""

    for price_type in "${price_types[@]}"; do
      old_price=$(echo "$old_prices" | jq -r ".\"$key\".\"$price_type\"")
      new_price=$(echo "$new_prices" | jq -r ".\"$key\".\"$price_type\"")

      if [[ "$old_price" != "null" && "$new_price" != "$old_price" ]]; then
        local change=$(awk "BEGIN {print ($new_price > $old_price) ? \"📈\" : \"📉\"}")
        key_changes+="$price_type: $change *$new_price VND*\n"
      elif [[ "$old_price" != "null" && "$new_price" == "$old_price" ]]; then
        local change="🟰"
        key_changes+="$price_type: $change *$new_price VND*\n"
      fi
    done

    if [[ -n "$key_changes" ]]; then
      changes+="$key:\n$key_changes\n"
    fi
  done

  printf "$changes"
}
current_prices=$(fetch_gold_prices)
previous_prices=$(load_previous_prices)

price_changes=$(compare_prices "$previous_prices" "$current_prices")

if [[ -n "$price_changes" ]]; then
  formatted_message=$(printf "Giá vàng đã được cập nhật!\n\n%s" "$price_changes")

  send_telegram_message "$formatted_message"
else
  echo "No price changes."
fi

save_current_prices "$current_prices"
