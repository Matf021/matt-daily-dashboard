# Matt Daily Dashboard

A retro CRT / Pip-Boy-inspired productivity dashboard built with **Rainmeter, Lua, and PowerShell**.

Matt Daily Dashboard combines quick note capture, task management, repeat-goal tracking, productivity statistics, achievements, and persistent local storage inside a compact desktop widget.

<p align="left">
  <img src="Assets/dashboard.png" width="250" alt="Matt Daily Notes dashboard">
</p>

> **Version 1.0 — Stable**

---

## Overview

Matt Daily Dashboard started as a simple desktop note widget and gradually evolved into a small state-driven productivity application.

The goal was to create something lightweight and useful for everyday organization while making the experience feel more like an interactive terminal system than a traditional to-do list.

The interface uses a monochrome CRT aesthetic with:

- phosphor-green typography
- glow effects
- CRT scanlines
- subtle flicker
- system status indicators
- command-style navigation
- animated achievement feedback

---

## Features

### Notes

The Notes view provides quick daily capture directly from the desktop.

Features include:

- timestamped entries
- multi-line notes
- automatic text wrapping
- scrolling
- entry counting
- empty-state handling
- manual archiving
- automatic daily archiving

Archived notes are stored as readable Markdown instead of a proprietary format.

---

### Task Management

Tasks can be created as either:

- **Normal tasks**
- **Repeat tasks**

Normal tasks behave like traditional to-do items and can be marked complete or incomplete.

Repeat tasks remain active after completion and instead record individual completion events.

Tasks can also be:

- viewed
- edited
- deleted
- completed
- tracked through history

---

### Repeat Goal Tracking

Repeat tasks can optionally track:

- weekly targets
- monthly targets
- weekly + monthly targets
- no target

For example:

```text
Jump rope
Weekly target: 5
Monthly target: 20
```

Completion progress is calculated from stored completion events rather than from a simple mutable counter.

This allows the application to preserve historical activity while dynamically calculating weekly and monthly progress.

---

### Goal Dashboard

The Goals view displays tracked repeat tasks and their current progress.

It includes:

- weekly view
- monthly view
- progress bars
- completion counts
- scrolling for larger goal lists
- recent completion history
- productivity statistics

---

### Achievement System

Matt Daily Dashboard includes a progression system tied to completed objectives.

Progression tracks include:

- Weekly
- Monthly
- Dual
- Total

Achievement thresholds begin at:

```text
1 → 5 → 10 → 25 → 50 → 100 → ...
```

Higher levels continue scaling beyond the initial thresholds.

Each track displays:

- current level
- completed objective count
- next threshold
- visual progress

---

### Special & Secret Badges

In addition to progression achievements, the widget includes behavior-based badges.

Current badges include:

| Badge | Requirement |
|---|---|
| **First Signal** | Unlock any achievement |
| **Dual Sync** | Complete a dual-target objective |
| **Night Owl** | Unlock an achievement between midnight and 4:59 AM |
| **Early Bird** | Unlock an achievement between 5:00 AM and 6:59 AM |
| **Overdrive** | Unlock three achievements in one day |
| **Perfect Week** | Complete every active weekly goal |

Some secret badges remain hidden until they are discovered.

---

## Demo

<p align="left">
  <img src="Assets/demo.gif" width="300" alt="Matt Daily Dashboard demo">
</p>

---

## Architecture

The project is split across three main technologies.

### Rainmeter

Rainmeter handles the desktop interface and rendering layer, including:

- UI layout
- meters
- input controls
- view switching
- interaction
- visual effects
- animations
- status indicators

### Lua

Lua handles most of the application logic.

It is responsible for:

- reading and rendering notes
- task rendering
- scrolling
- goal calculations
- statistics
- state management
- achievement progression
- badge logic
- navigation
- history views

### PowerShell

PowerShell is used for persistent file operations, including:

- saving notes
- archiving notes
- creating tasks
- editing tasks
- deleting tasks
- toggling task completion
- clearing completed tasks
- recording repeat-task completion events

---

## Project Structure

```text
matt-daily-dashboard/
│
├── Daily Notes/
│   └── DailyNotes.ini
│
├── README.md
├── .gitignore
│
├── Assets/
│   ├── dashboard.png
│   └── demo.gif
│
├── @Resources/
│   ├── ReadNotes.lua
│   ├── ReadTasks.lua
│   ├── GoalTracker.lua
│   ├── GoalInsights.lua
│   ├── Achievement.lua
│   ├── ViewController.lua
│   ├── EntryCount.lua
│   │
│   ├── Today.example.txt
│   ├── Tasks.example.txt
│   ├── TaskHistory.example.txt
│   ├── CurrentDate.example.txt
│   ├── AchievementHistory.example.txt
│   ├── BadgeHistory.example.txt
│   │
│   └── Sprites/
│
└── Scripts/
    ├── AddNote.ps1
    ├── AddTask.ps1
    ├── ArchiveNotes.ps1
    ├── ClearCompletedTasks.ps1
    ├── DeleteTask.ps1
    ├── EditTask.ps1
    └── ToggleTask.ps1
```

---

## Data Model

### Tasks

Tasks use the following format:

```text
status|type|id|weeklyGoal|monthlyGoal|text
```

Example:

```text
0|repeat|12|5|20|Jump rope
```

Fields:

```text
status       0 = active, 1 = completed
type         normal or repeat
id           unique task identifier
weeklyGoal   weekly completion target
monthlyGoal  monthly completion target
text         task name
```

---

### Completion History

Repeat-task completion events are stored separately:

```text
taskId|timestamp
```

Example:

```text
12|2026-10-29T14:32:17
```

This event-based structure allows the application to calculate weekly and monthly progress from historical data rather than relying on a single stored counter.

---

## Local-First Design

Matt Daily Dashboard does not require a database, account, API, or cloud service.

Application data is stored locally using plain-text files.

This keeps the project:

- lightweight
- transparent
- portable
- easy to inspect
- easy to back up

Personal runtime data is intentionally excluded from version control. Files containing notes, tasks, completion history, achievement history, badge history, and local date state remain on the user's machine and are ignored by Git.

Sample `.example.txt` files are included in the repository to document the expected data formats without exposing personal content.

---

## Notes Archive

Archived notes are written to:

```text
Documents\Daily Notes\Daily Notes.md
```

Each day becomes its own Markdown section.

If the archive file does not already exist, it is created automatically the first time notes are archived.

Example:

```markdown
## October 29, 2026

14:20
Finish GitHub README

16:05
Test achievement system
```

---

## Installation

### Requirements

- Windows
- [Rainmeter](https://www.rainmeter.net/)
- PowerShell

### Recommended Installation

1. Go to the repository's **Releases** page.

2. Download:

```text
Matt-Daily-Dashboard-v1.0.0.rmskin
```

3. Double-click the downloaded `.rmskin` file.

4. Install it using the Rainmeter Skin Installer.

5. Matt Daily Dashboard will be added to Rainmeter and can be loaded from:

```text
MattDaily\Daily Notes\DailyNotes.ini
```

The installer includes clean runtime data files, so no personal notes, tasks, history, or achievement data from the developer are included.

### Manual Installation

For development or manual setup:

1. Clone or download this repository.

2. Place the project folder inside:

```text
Documents\Rainmeter\Skins\
```

For example:

```text
Documents\Rainmeter\Skins\matt-daily-dashboard\
```

3. Create the local runtime data files inside `@Resources/`.

The repository includes `.example.txt` templates. Create copies of the templates using the following filenames:

```text
Today.txt
Tasks.txt
TaskHistory.txt
CurrentDate.txt
AchievementHistory.txt
BadgeHistory.txt
```

These runtime files are ignored by Git so personal notes, task history, and achievement data remain local.

4. Open Rainmeter.

5. Refresh the skin list.

6. Load:

```text
matt-daily-dashboard\Daily Notes\DailyNotes.ini
```

---

## Development Highlights

Some of the more interesting engineering challenges in the project included:

- coordinating application state across multiple Rainmeter views
- maintaining persistent task IDs
- separating task configuration from completion history
- dynamically calculating weekly and monthly progress
- preventing UI state from leaking between views
- implementing task creation and editing workflows
- building scrollable interfaces within Rainmeter
- coordinating Rainmeter, Lua, and PowerShell
- designing achievement progression
- implementing hidden badge conditions
- managing persistent local data without a database

---

## Version 1.0

Version 1.0 includes:

- quick notes
- note archiving
- normal tasks
- repeat tasks
- task editing
- task deletion
- weekly goals
- monthly goals
- goal history
- productivity statistics
- achievement progression
- special achievements
- secret achievements
- achievement popups
- persistent local storage
- CRT-inspired interface
- `.rmskin` installer

The primary application flows were smoke-tested before the v1.0 release.

---

## Future Ideas

Possible future versions may explore:

- streak tracking
- additional achievement types
- expanded analytics
- customizable themes
- configurable settings
- data export/import
- additional productivity modules

Version 1.0 is currently considered feature-complete.

---

## Author

**Matias Franco**

Built as a personal productivity tool and software engineering project using **Rainmeter, Lua, and PowerShell**.

© 2026 Matias Franco. All rights reserved.
