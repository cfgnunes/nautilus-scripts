# File Manager Actions

This project is a collection of actions designed to enhance the functionality of file managers through intuitive right-click actions on files and directories.

Compatible with file managers:

- [GNOME Files (Nautilus)](https://gitlab.gnome.org/GNOME/nautilus)
- [Caja](https://github.com/mate-desktop/caja)
- [Dolphin](https://github.com/KDE/dolphin)
- [Nemo](https://github.com/linuxmint/nemo)
- [PCManFM-Qt](https://github.com/lxqt/pcmanfm-qt)
- [Thunar](https://gitlab.xfce.org/xfce/thunar)

![screenshot](.assets/screenshot.png)

## Installing

To install, just run the following command in the terminal:

```sh
bash install.sh
```

## Advantages

While numerous scripts are available for file managers on the web, many suffer from poor functionality, lack of error checking, and dependency management. Some scripts only work with files that don't have special characters in their names, among other limitations. To address these shortcomings, I have developed my own set of scripts, which offer the following advantages:

- **Parallel task execution**: Processes multiple files simultaneously. Very fast!
- **Progress dialog**: Displays a progress dialog and allows interruption of tasks at any time.
- **Status notifications**: Notifies users of dependency errors and MIME types.
- **Dependency management**: Prompts users to install any missing dependencies.
- **Non-destructive output**: Never overwrites the input file; the output is distinct.
- **Log file**: Produces an `Errors.log` file when a task ends with an error.
- **Direct usage**: Direct usage without requiring input parameters.
- **Keyboard shortcuts**: Provides keyboard shortcuts for the scripts.
- **File manager compatibility**: Designed for major file managers like GNOME Files (Nautilus), Dolphin, Caja, Nemo and Thunar.
- **Distro compatibility**: Designed to work on major GNU/Linux distributions, such as Ubuntu, Mint, Debian, Fedora, and Manjaro.
- **Easy adaptation**: Scripts can be easily copied and adapted for other purposes.
- **Bash implementation**: All scripts are implemented in Bash. So, the scripts work well in the shell (without a graphical interface) and file managers.
- **Shell script validation**: All scripts have been checked using [ShellCheck](https://github.com/koalaman/shellcheck).

## Keyboard Shortcuts

| Key                 | Action                        |
| ------------------- | ----------------------------- |
| `F3`                | Code Editor                   |
| `F4`                | Terminal                      |
| `F7`                | Disk Usage Analyzer           |
| `<Control>E`        | Extract Here                  |
| `<Control><Alt>C`   | Compress...                   |
| `<Control><Alt>G`   | Compress to 'tar.gz' (each)   |
| `<Control><Alt>V`   | Paste as hard link            |
| `<Control><Alt>X`   | Compress to 'tar.xz' (each)   |
| `<Control><Alt>Z`   | Compress to 'zip' (each)      |
| `<Control><Shift>C` | Compare items                 |
| `<Control><Shift>E` | List empty directories        |
| `<Control><Shift>F` | List file information         |
| `<Control><Shift>G` | Git clone (URLs in clipboard) |
| `<Control><Shift>H` | List hidden items             |
| `<Control><Shift>O` | Open item location            |
| `<Control><Shift>P` | List permissions and owners   |
| `<Control><Shift>U` | List duplicate files          |
| `<Control><Shift>V` | Paste as symbolic link        |
| `<Control><Shift>X` | Download (URLs in clipboard)  |

## Compatibility

File managers compatibility:

| File manager           | Environment | Menu integration | Shortcuts |
| ---------------------- | ----------- | ---------------- | --------- |
| GNOME Files (Nautilus) | GNOME       | Yes              | Yes       |
| Caja                   | MATE        | Yes              | Yes       |
| Dolphin                | KDE Plasma  | Yes              | No        |
| Nemo                   | Cinnamon    | Yes              | Yes       |
| PCManFM-Qt             | LXQt        | Yes              | No        |
| Thunar                 | Xfce        | Yes              | Yes       |

Most scripts have been tested on the following GNU/Linux distributions:

- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 12 (Gnome and KDE)
- Fedora Workstation 39
- Kubuntu 22.04
- Lubuntu 22.04
- Manjaro 23 (Gnome)
- Mint 21 (Cinnamon and Mate)
- openSUSE Tumbleweed 2024 (Gnome)
- Xubuntu 23.10, 24.04
- Zorin OS Core 17.1

## Contributing

If you spot a bug or want to improve the code or even improve the content, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.
