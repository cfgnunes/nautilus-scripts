# Nautilus scripts

This is a collection of scripts designed to enhance the functionality of file managers such as [GNOME Files](https://gitlab.gnome.org/GNOME/nautilus), [Caja](https://github.com/mate-desktop/caja), and [Nemo](https://github.com/linuxmint/nemo).

![screenshot](screenshot.png)

While there are numerous scripts available for GNOME Files on the web, many of them suffer from issues like poor functionality, lack of error checking, and dependency management. Some scripts only work with files that don't have spaces in their names, among other limitations. To address these shortcomings, I have developed my own set of scripts, which offer the following advantages:

- **Parallel task execution**: Processes multiple files simultaneously.
- **Progress dialog**: Displays a progress dialog and allows interruption of tasks at any time.
- **Easy adaptation**: Scripts are easily copied and adapted for other purposes.
- **Direct usage**: Enables direct usage without requiring input parameters.
- **Status notifications**: Notifies users of dependency errors and MIME types.
- **Non-destructive output**: Never overwrites the input file; the output is distinct from the input.
- **Log file**: Produces an `Errors.log` file when a task ends with an error.
- **Dependency management**: Prompts users to install any missing dependencies.
- **Compatibility with any file manager**: Works with any file manager.
- **Keyboard shortcuts**: Provides keyboard shortcuts for the scripts (refer to the `scripts-accels` file).
- **Bash implementation**: All scripts are implemented in Bash.
- **Shell script validation**: All scripts have been checked using [ShellCheck](https://github.com/koalaman/shellcheck).

## Installing

To install in GNOME Files (Nautilus), Caja or Nemo, just run the following command in the terminal:

```sh
bash install.sh
```

## Known issues

- Doesn't support very long list of input files (Argument list too long).

## Contributing

If you spot a bug, or want to improve the code, or even improve the content, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.
