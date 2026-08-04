# Linux Monitoring Tool

A production-inspired Linux log monitoring tool built using Bash scripting.

The tool continuously monitors one or more log files, detects newly added log entries, generates monitoring reports, and sends email alerts whenever the configured error threshold is exceeded.

The project demonstrates Linux administration, Bash scripting, automation, state management, scheduling using Cron, and SMTP email integration.

---

# Features

- Monitor multiple log files
- Incremental log scanning (only newly added logs)
- Separate state file for every log file
- Automatic log rotation detection
- File locking using `flock`
- Execution logging
- Monitoring report generation
- Email alerts using Gmail SMTP (msmtp)
- Duplicate alert suppression using `EMAIL_SENT`
- Cron scheduling support
- Configuration driven design

---

# Project Architecture

```
                +----------------------+
                |   config/config.env  |
                +----------+-----------+
                           |
                           v
                    log_monitor.sh
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
   Validate Log     Scan New Logs     Load State File
          |                |                |
          +----------------+----------------+
                           |
                           v
                  Generate Report
                           |
                           v
                    Check Threshold
                           |
              +------------+------------+
              |                         |
              v                         v
      No Alert Needed             Send Email Alert
              |                         |
              +------------+------------+
                           |
                           v
                    Update State File
```

---

# Folder Structure

```text
linux-monitoring-tool/
│
├── config/
│   └── config.env
│
├── logs/
│   ├── application.log
│   ├── monitor.log
│   └── monitor_execution.log
│
├── state/
│   └── logs_application_log
│
├── scripts/
│   └── log_monitor.sh
│
└── cron/
    └── log-monitor.cron
```

---

# Installation

Clone the repository

```bash
git clone <repository-url>
cd linux-monitoring-tool
```

Make the script executable.

```bash
chmod +x scripts/log_monitor.sh
```

---

# Configuration

Update the configuration file.

```bash
config/config.env
```

Example

```bash
LOG_FILES=(
    "logs/application.log"
)

ERROR_THRESHOLD=2

ALERT_EMAIL="your-email@gmail.com"

MONITOR_LOG="logs/monitor.log"

MONITOR_EXECUTION_LOG="logs/monitor_execution.log"
```

---

# Email Configuration

This project uses **msmtp** with Gmail SMTP.

Requirements:

- Gmail account
- Two-Factor Authentication enabled
- Gmail App Password
- msmtp installed

---

# Running the Project

```bash
bash scripts/log_monitor.sh
```

---

# Cron Configuration

Example:

```cron
*/5 * * * * ~/linux-monitoring-tool/scripts/log_monitor.sh
```

Load Cron configuration.

```bash
crontab cron/log-monitor.cron
```

---

# Sample Monitoring Report

```text
================ Linux Monitor Report ================

Log File      : logs/application.log

INFO Count    : 10
WARNING Count : 2
ERROR Count   : 3

Status        : ALERT

Errors

Database connection timeout

Redis connection failed

======================================================
```

---

# State Management

Each monitored log file has its own state file.

Example:

```text
LastProcessed=150
EMAIL_SENT=false
```

This prevents duplicate processing and duplicate email alerts.

---

# Technologies Used

- Bash
- Linux
- Cron
- msmtp
- Gmail SMTP
- flock
- sed
- awk
- grep

---

# Future Enhancements

- Disk usage monitoring
- CPU monitoring
- Memory monitoring
- Slack notifications
- Teams notifications
- HTML email reports
- Log severity filtering
- Docker container monitoring

---

# Lessons Learned

This project helped me understand:

- Bash scripting
- Linux process management
- File locking
- Cron scheduling
- SMTP email workflow
- State management
- Log rotation handling
- Incremental log processing
- Production debugging techniques

---

# Author

Vinay Joshi

GitHub: https://github.com/ivinay1

# Engineering Decisions

## Why separate state files?

Each log file maintains an independent processing state, allowing multiple log files to be monitored without interfering with each other.

## Why use flock?

Prevents concurrent script executions when the previous Cron job has not yet finished.

## Why EMAIL_SENT?

Prevents duplicate email alerts for the same incident while allowing new alerts once the issue has been resolved.

## Why incremental scanning?

Improves performance by processing only newly appended log entries instead of rescanning the entire log file.
