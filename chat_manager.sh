#!/bin/bash

source .env

send_telegram_message() {
  local chat_id="$1"
  local message="$2"
  curl -s -X POST "$TELEGRAM_API_URL/sendMessage" \
    -d chat_id="$chat_id" \
    -d text="$message" \
    -d parse_mode="Markdown" >/dev/null
}

get_updates() {
  local offset="$1"
  curl -s -X GET "$TELEGRAM_API_URL/getUpdates" -d offset="$offset" -d timeout=60
}

chat_id_exists() {
  local chat_id="$1"
  grep -Fxq "$chat_id" "$CHAT_IDS_FILE" 2>/dev/null
}

store_chat_id() {
  local chat_id="$1"
  echo "$chat_id" >>"$CHAT_IDS_FILE"
}

handle_new_user() {
  local chat_id="$1"
  local text="$2"

  if ! chat_id_exists "$chat_id"; then
    store_chat_id "$chat_id"

    local welcome_message="Chào mừng bạn đến với Bot thông báo giá vàng tại Kim Phát! Bạn sẽ bắt đầu nhận được thông báo khi giá vàng biến động"
    send_telegram_message "$chat_id" "$welcome_message"
  fi

}

send_price_update() {
  local message="$1"

  while read -r chat_id; do
    send_telegram_message "$chat_id" "$message"
  done <"$CHAT_IDS_FILE"
}

initialize_offset_file() {
  if [[ ! -f "$OFFSET_FILE" ]]; then
    echo "0" >"$OFFSET_FILE" # Create the file with initial offset as 0
  fi
}

while true; do
  if [[ -f "$OFFSET_FILE" ]]; then
    OFFSET=$(cat "$OFFSET_FILE")
  else
    OFFSET=0
  fi

  updates=$(get_updates "$OFFSET")

  messages=$(echo "$updates" | jq -c '.result[]')

  echo "$messages" | while read -r message; do
    chat_id=$(echo "$message" | jq -r '.message.chat.id')
    text=$(echo "$message" | jq -r '.message.text')
    update_id=$(echo "$message" | jq -r '.update_id')

    handle_new_user "$chat_id" "$text"

    new_offset=$((update_id + 1))
    echo "$new_offset" >"$OFFSET_FILE"
  done

  price_update_message="Gold price updated! Your price info goes here."

  send_price_update "$price_update_message"
done
