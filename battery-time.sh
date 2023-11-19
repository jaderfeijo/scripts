#!/usr/bin/env python

import subprocess
import re
from datetime import datetime, timedelta

def get_log_data():
    # Command to get relevant log entries
    command = ["log", "show", "--predicate",
               '(process == "powerd") AND (eventMessage CONTAINS "Using AC" OR eventMessage CONTAINS "Using Batt" OR eventMessage CONTAINS "Sleep" OR eventMessage CONTAINS "Wake")',
               "--last", "24h"]  # Looking back 24 hours

    # Run the command and capture the output
    result = subprocess.run(command, capture_output=True, text=True)
    return result.stdout

def parse_logs(log_data):
    events = []
    for line in log_data.splitlines():
        # Extract timestamp and message
        match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).* (Using Batt|Using AC|Sleep|Wake)', line)
        if match:
            timestamp_str, message = match.groups()
            timestamp = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
            events.append((timestamp, message))

    # Diagnostic print to see the last few events
    print("Last few events in the log:")
    for event in events[-10:]:
        print(event)

    # Find the last unplugging event
    last_unplugged_time = None
    for event in reversed(events):
        if event[1] == "Using Batt":
            last_unplugged_time = event[0]
            break

    if last_unplugged_time is None:
        return None, None, None  # No unplugging event found

    # Calculate times since the last unplugging
    total_battery_time = timedelta(0)
    total_sleep_time = timedelta(0)
    for i in range(len(events)):
        if events[i][0] < last_unplugged_time:
            continue

        if events[i][1] == "Sleep":
            for j in range(i+1, len(events)):
                if events[j][1] == "Wake":
                    total_sleep_time += events[j][0] - events[i][0]
                    break

        if events[i][1] == "Using Batt":
            end_time = events[i+1][0] if i+1 < len(events) else datetime.now()
            total_battery_time += end_time - events[i][0]

    total_active_time = total_battery_time - total_sleep_time
    return total_battery_time, total_sleep_time, total_active_time

def main():
    print("Calculating...")
    log_data = get_log_data()
    total_battery_time, total_sleep_time, total_active_time = parse_logs(log_data)

    if total_battery_time is None:
        print("No unplugging event found in the logs.")
    else:
        print(f"Total Time on Battery Since Last Unplugged: {total_battery_time}")
        print(f"Total Sleep Time Since Last Unplugged: {total_sleep_time}")
        print(f"Total Active Time on Battery (Excluding Sleep) Since Last Unplugged: {total_active_time}")

if __name__ == "__main__":
    main()
