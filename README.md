# Enhanced File Manager Actions

Extra options in the right-click menu of your file manager. Convert audio and video, handle documents and images, rename, compress, or encrypt files, and do other everyday tasks on GNOME, KDE, Xfce, and more.

[![Supported](https://img.shields.io/badge/Supported-GNOME%20%7C%20KDE%20%7C%20MATE%20%7C%20Xfce%20%7C%20Cinnamon%20%7C%20LXQt-339933?labelColor=333333)](#compatibility)

[![Screenshot](https://cfgnunes.github.io/nautilus-scripts/screenshot.svg)](#installation)

## Installation

### Option 1: Online installation (recommended)

You can use either **wget** or **curl**. Choose **one** of the following commands and run it in your terminal:

#### Using `wget`

```bash
bash <(wget -qO- https://cfgnunes.github.io/nautilus-scripts/install.sh)
```

#### Using `curl`

```bash
bash <(curl -fsSL https://cfgnunes.github.io/nautilus-scripts/install.sh)
```

### Option 2: Local installation

After cloning this repository, run the following command:

```bash
bash install.sh
```

## Highlights

- **Parallel task execution**: Processes multiple files simultaneously. Very fast!
- **Multi-language support**: Automatically detects the system language and displays messages in the appropriate language.
- **Progress dialog**: Displays a progress dialog and allows interruption of tasks at any time.
- **Sandboxed execution**: Runs commands in a secure sandbox using Bubblewrap.
- **Dependency management**: Prompts users to install any missing dependencies.
- **Keyboard accelerators**: Provides keyboard shortcuts for some scripts.
- **Easy access to recent scripts**: Includes a menu, _Accessed recently_, to quickly access recently used scripts.
- **Category-based installation:** The installer allows you to choose which script categories you want to install, so there's no need to install everything.
- **File manager compatibility**: Designed for major file managers like GNOME Files (Nautilus), Nemo, Caja, Dolphin, and Thunar.
- **Distro compatibility**: Works on major GNU/Linux distributions, such as Debian, Ubuntu, Fedora, and Arch Linux.

## Keyboard accelerators

| Key                                               | Action                       |
| ------------------------------------------------- | ---------------------------- |
| <kbd>F4</kbd>                                     | Terminal                     |
| <kbd>Shift</kbd> + <kbd>F4</kbd>                  | Terminal (synced panes)      |
| <kbd>F7</kbd>                                     | Code editor                  |
| <kbd>F12</kbd>                                    | Disk usage analyzer          |
| <kbd>Ctrl</kbd> + <kbd>E</kbd>                    | Extract here                 |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>G</kbd>   | Compress to 'tar.gz'         |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>S</kbd>   | Compress to 'tar.zst'        |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>X</kbd>   | Compress to 'tar.xz'         |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>Z</kbd>   | Compress to 'zip'            |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd>   | Show file information        |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd>   | Show file metadata           |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>0</kbd>   | Find empty files             |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>E</kbd>   | Find empty directories       |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>J</kbd>   | Find junk files              |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd>   | Find duplicate files         |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>H</kbd>   | List hidden files            |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>P</kbd>   | List permissions and owners  |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>B</kbd>   | List largest files           |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>R</kbd>   | List recent files            |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>W</kbd>   | Git: Open repository website |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>C</kbd>   | Copy file names              |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>V</kbd>   | Paste as hard link           |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | Paste as symbolic link       |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Create backup (via Rsync)    |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> | Compare items                |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>H</kbd> | Compute all checksums        |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>O</kbd> | Open item location           |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>G</kbd> | Git: Clone URLs              |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> | Git: Reset and pull          |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>X</kbd> | URL: Download file           |
| <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>V</kbd>  | Paste clipboard contents     |
| <kbd>Shift</kbd> + <kbd>F12</kbd>                 | Update scripts               |

## Compatibility

| File manager           | Environment | Menu integration | Keyboard accelerators | Menu "Accessed recently" |
| ---------------------- | ----------- | ---------------- | --------------------- | ------------------------ |
| GNOME Files (Nautilus) | GNOME       | 🟢                | 🟢                     | 🟢                        |
| Nemo                   | Cinnamon    | 🟢                | 🟢                     | 🟢                        |
| Caja                   | MATE        | 🟢                | 🟢                     | 🟢                        |
| Thunar                 | Xfce        | 🟢                | 🟢                     | 🔴                        |
| Dolphin                | KDE Plasma  | 🟢                | 🔴                     | 🔴                        |
| PCManFM-Qt             | LXQt        | 🟢                | 🔴                     | 🔴                        |
| PCManFM                | LXDE        | 🟢                | 🔴                     | 🔴                        |

All scripts are written in Bash and require version 4.3 or higher.

## Batch mode for large file selections

For very large selections (e.g., 10,000 input files), use **batch mode**: place all the input files in a folder whose name contains the word `batch`, then run the action on that folder. The scripts will process the files individually, avoiding the "argument list too long" error.

## Contributing

If you spot a bug or want to improve the code or even improve the content, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.

If you'd like to translate this project into your native language, feel free to send me the translated file: [en_template.pot](https://github.com/cfgnunes/nautilus-scripts/blob/main/.po/en_template.pot)

## Contributors

Thank you for contributing to this project:

[![contributors](https://contrib.rocks/image?repo=cfgnunes/nautilus-scripts)](https://github.com/cfgnunes/nautilus-scripts/graphs/contributors)

Special thanks to everyone who contributed to the translation of this project:

- 🇧🇷 **Nathália Medeiros** - Brazilian Portuguese.
- 🇨🇳 **Jove Yu (@JoveYu)** - Chinese.
- 🇪🇸 **Maravento (@maravento)** - Spanish.
- 🇩🇪 **Stephan Mikwauschk (@Pappmann)** and **La-vaos (@la-vaos)** - German.
- 🇻🇳 **Loc Huynh (@hthienloc)** - Vietnamese.
- 🇫🇷 **Germain Rémi (@remigermain)** - French.
- 🇷🇺 **Vladimir Kosolapov (@vmkspv)** - Russian.
- 🇮🇱 **Omer I.S. (@omeritzics)** - Hebrew.
- 🇳🇱 **Heimen Stoffels (@Vistaus)** - Dutch.
- 🇰🇷 **Yun Juhwan (@g-yunjh)** - Korean.
- 🇯🇵 **Camegone (@camegone)** - Japanese.
- 🇹🇷 **Yaşar Çiv (@yasarciv)** - Turkish.
- 🇬🇪 **Temuri Doghonadze (@NorwayFun)** - Georgian.
- 🇦🇿 **Jamal Ali (@jamalkamaladdin)** - Azerbaijani.

## Star history

If you find this project useful, please consider giving it a ⭐ on GitHub. It helps motivate further development. Thank you!

[![Star history chart](https://api.star-history.com/svg?repos=cfgnunes%2Fnautilus-scripts)](https://api.star-history.com/svg?repos=cfgnunes%2Fnautilus-scripts)
