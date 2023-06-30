# Nautilus scripts

This is a collection of scripts designed to enhance the functionality of file managers such as [GNOME Files](https://gitlab.gnome.org/GNOME/nautilus), [Caja](https://github.com/mate-desktop/caja), and [Nemo](https://github.com/linuxmint/nemo).

![screenshot](screenshot.png)

While there are numerous scripts available for GNOME Files on the web, many of them suffer from issues like poor functionality, lack of error checking, and dependency management. Some scripts only work with files that don't have spaces in their names, among other limitations. To address these shortcomings, I have developed my own set of scripts, which offer the following advantages:

- **Parallel Task Execution**: Processes multiple files simultaneously.
- **Progress Dialog**: Displays a progress dialog and allows interruption of tasks at any time.
- **Easy Adaptation**: Scripts are easily copied and adapted for other purposes.
- **Keyboard Shortcuts**: Provides keyboard shortcuts for direct access to the scripts (refer to the `scripts-accels` file).
- **Direct Usage**: Enables direct usage without requiring input parameters.
- **Status Notifications**: Notifies users of dependency errors and MIME types.
- **Dependency Management**: Prompts users to install any missing dependencies.
- **Compatibility with Any File Manager**: Works with any file manager, without relying on `$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` or Nemo equivalents.
- **Non-destructive Output**: Never overwrites the input file; the output is distinct from the input.
- **Bash Implementation**: All scripts are implemented in Bash.
- **Shell Script Validation**: All shell scripts have been checked using [shellcheck](https://github.com/koalaman/shellcheck).

## Installing

To install in GNOME Files (Nautilus), Caja or Nemo, just run the following command in the terminal:

```sh
bash install.sh
```

## Contributing

If you spot a bug, or want to improve the code, or even improve the content, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.
