# Enhanced File Manager Actions for Linux

This project offers a collection of file manager actions, also known as Nautilus Scripts, designed to enhance the functionality of file managers. With intuitive right-click options for files and directories, it simplifies tasks, boosts productivity, and provides a more efficient workflow.

![screenshot](.assets/screenshot.png)

## Installing

You can install in two ways:

### Option 1 - Online installation (recommended)

Run the following command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cfgnunes/nautilus-scripts/HEAD/install.sh)"
```

### Option 2 - Local installation

After cloning this repository, run the following command:

```bash
bash install.sh
```

## Advantages

While numerous scripts are available for file managers on the web, many suffer from poor functionality, lack of error checking, and dependency management. Some scripts only work with files that don't have special characters in their names, among other limitations. To address these shortcomings, I have developed my own set of scripts, which offer the following advantages:

- **Parallel task execution**: Processes multiple files simultaneously. Very fast!
- **Progress dialog**: Displays a progress dialog and allows interruption of tasks at any time.
- **Status notifications**: Notifies users of dependency errors and MIME types.
- **Dependency management**: Prompts users to install any missing dependencies.
- **Remote file support:** Works with files stored on remote servers.
- **Non-destructive output**: Never overwrites the input file; the output is distinct.
- **Log file**: Produces an `Errors.log` file when a task finishes with an error.
- **Direct usage**: Direct usage without requiring input parameters.
- **Keyboard accelerators**: Provides keyboard shortcuts for some scripts.
- **File manager compatibility**: Designed for major file managers like GNOME Files (Nautilus), Dolphin, Caja, Nemo, PCManFM-Qt and Thunar.
- **Distro compatibility**: Designed to work on major GNU/Linux distributions, such as Ubuntu, Mint, Debian, Fedora, and Manjaro.
- **Easy adaptation**: Scripts can be easily copied and adapted for other purposes.
- **Bash implementation**: All scripts are implemented in Bash. So, the scripts work well in the shell (without a graphical interface) and file managers.
- **Shell script validation**: All scripts have been checked using [ShellCheck](https://github.com/koalaman/shellcheck).
- **Easy access to recent scripts**: Includes a menu, `Accessed recently`, to quickly access recently used scripts, saving time and streamlining workflows.

**Design philosophy:** Fewer clicks, dependencies, and verbose notifications, with a simple and intuitive directory structure.

## Keyboard accelerators

| Key                 | Action                            |
| ------------------- | --------------------------------- |
| `F3`                | Code Editor                       |
| `F4`                | Terminal                          |
| `F7`                | Disk Usage Analyzer               |
| `<Control>E`        | Extract here                      |
| `<Control><Alt>C`   | Compress...                       |
| `<Control><Alt>G`   | Compress to .tar.gz (each)        |
| `<Control><Alt>X`   | Compress to .tar.xz (each)        |
| `<Control><Alt>S`   | Compress to .tar.zst (each)       |
| `<Control><Alt>Z`   | Compress to .zip (each)           |
| `<Control><Alt>V`   | Paste as hard link                |
| `<Control><Shift>V` | Paste as symbolic link            |
| `<Control><Shift>C` | Compare items                     |
| `<Control><Shift>G` | Git: Clone URLs (clipboard, file) |
| `<Control><Shift>R` | Git: Reset and pull               |
| `<Control><Shift>X` | URL: Download (clipboard, file)   |
| `<Control><Shift>O` | Open item location                |
| `<Control><Shift>E` | Find empty directories            |
| `<Control><Shift>H` | Find hidden items                 |
| `<Control><Shift>U` | Find duplicate files              |
| `<Control><Shift>P` | List permissions and owners       |
| `<Control><Shift>Y` | Show files information            |
| `<Control><Alt>1`   | Show files MIME types             |
| `<Control><Alt>2`   | Text: List file issues            |
| `<Control><Alt>3`   | Text: List files with bad chars   |
| `<Control><Alt>4`   | Text: List encodings              |
| `<Control><Alt>5`   | Text: List line breaks            |
| `<Control><Alt>6`   | Text: List line count             |
| `<Control><Alt>7`   | Text: List max line length        |
| `<Control><Alt>8`   | Text: List word count             |
| `<Control><Alt>9`   | List largest directories          |
| `<Control><Alt>0`   | List largest files                |

## Compatibility

File managers compatibility:

| File manager           | Environment | Menu integration | Application shortcuts | Keyboard accelerators | Menu "Accessed recently" |
| ---------------------- | ----------- | ---------------- | --------------------- | --------------------- | ------------------------ |
| GNOME Files (Nautilus) | GNOME       | 🟢                | 🟢                     | 🟢                     | 🟢                        |
| Caja                   | MATE        | 🟢                | 🟢                     | 🟢                     | 🟢                        |
| Nemo                   | Cinnamon    | 🟢                | 🟢                     | 🟢                     | 🟢                        |
| Thunar                 | Xfce        | 🟢                | 🟢                     | 🟢                     | 🔴                        |
| Dolphin                | KDE Plasma  | 🟢                | 🟢                     | 🔴                     | 🔴                        |
| PCManFM-Qt             | LXQt        | 🟢                | 🟢                     | 🔴                     | 🔴                        |

Most scripts have been tested on the following GNU/Linux distributions:

- Debian/Ubuntu
  - Ubuntu 14.04, 16.04, 18.04, 20.04, 22.04, 24.04
  - Debian 12, 13 (Gnome and KDE)
  - Kubuntu 22.04, 24.04
  - Lubuntu 22.04, 24.04
  - Xubuntu 23.10, 24.04
  - KDE neon 2024, 2025
  - Mint 21, 22 (Cinnamon, MATE and Xfce)
  - Zorin OS Core 17.1, 17.2
- Fedora
  - Workstation 39, 40, 41, 42
- Arch Linux
  - CachyOS
  - EndeavourOS
  - Manjaro 23, 24, 25 (Gnome)
- openSUSE
  - Tumbleweed 2024, 2025 (Gnome)

## Handling large input lists

This project includes a functionality specifically designed to manage scenarios where input lists are too large for processing (e.g., 100,000 input files). Excessively large input lists can lead to errors like:

`Could not start application: Failed to execute child process "/bin/sh" (Argument list too long)`

In some cases, the scripts may fail to run. To avoid such issues, follow these steps:

1. Create a single directory with a name that includes the word `batch`;
2. Place all the files you want to process into this directory;
3. Execute the desired script using this directory as the input.

When batch mode is detected, the script will recognize the directory as a special case and process each file inside it individually, instead of treating the entire directory as a single input.
This approach prevents errors caused by excessively long argument lists and ensures reliable execution.

## Contributing

If you spot a bug or want to improve the code or even improve the content, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.
