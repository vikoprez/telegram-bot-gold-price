# Gold Price Monitor Bot

This project monitors gold prices on [http://kimphatminhkhoi.coimedia.com](http://kimphatminhkhoi.coimedia.com) and notifies users of any changes via Telegram. The bot periodically fetches the gold prices, compares them with previous data, and sends a formatted message if any price has changed. It also tracks users and manages Telegram chat IDs to handle notifications.

## Features
- Monitors gold prices for selected types.
- Sends updates via Telegram only if any price changes.
- Logs results with timestamps.
- Supports multiple Telegram chat IDs for notifications.

## Requirements
- Bash
- `curl` for sending Telegram messages and fetching website data
- `jq` for handling JSON data
- A Telegram Bot token and a chat ID

## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vikoprez/telegram-bot-gold-price.git
   cd telegram-bot-gold-price
   ```

2. **Set up environment variables:**
   Open the **.env.template** file and replace the placeholders with your actual Telegram Bot token and initial chat ID, then rename it to **.env**.

3. **Run the Bot:**
   Run the script manually to test:
   ```bash
   ./run.sh
   ```
   To automatically check prices every hour, set up a cron job:
   ```bash
   crontab -e
   # Add the following line to check every hour
   0 * * * * /path/to/run.sh >> /path/to/price_monitor.log 2>&1

4. **Chat Management:**
   New chat IDs are automatically stored in `chat_ids.txt`. The bot will greet new users with a welcome message.

## File Overview

- `run.sh`: Main script to monitor gold prices, send Telegram notifications, and log results.
- `chat_manager.sh`: Script for managing new Telegram users.
- `gold_prices.json`: Stores previous prices for comparison.
- `chat_ids.txt`: Stores chat IDs for Telegram notifications.

## License
This project is open-source and licensed under the MIT License.
