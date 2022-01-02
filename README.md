# Nautilus Scripts

There is a lot of nautilus scripts all over the web.
But a lot of these scripts are not working very well.
No check for errors and no check for dependencies.
Some of them only work in nautilus, some others only in nemo.
Some of them only work with files that not contained spaces, and so on.
So I decided to write my own scripts, that has the following advantages:

- It runs the processes in parallel: processes multiple files at same time;
- It is easy to copy and adapt the scripts for other purposes;
- It has status notifications (dependency errors, supported mime-type);
- It works in any file manager: no use of the variable \$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS or NEMO equivalent;
- It has an direct usage, without an input box to ask parameters;
- It never overwrites the input file. The output is different of the input;
- All shell scripts were checked by [shellcheck](https://github.com/koalaman/shellcheck).

## Getting Started

### Installing in nautilus file manager

```sh
git clone https://github.com/cfgnunes/nautilus-scripts.git ~/.local/share/nautilus/scripts
```

### Installing in nemo file manager

```sh
git clone https://github.com/cfgnunes/nautilus-scripts.git ~/.gnome2/nemo-scripts/scripts
```

### Installing in caja file manager

```sh
git clone https://github.com/cfgnunes/nautilus-scripts.git ~/.config/caja/scripts
```

## Contributing

If you spot a bug, or want to improve the code, or even make the content better, you can do the following:

- [Open an issue](https://github.com/cfgnunes/nautilus-scripts/issues/new)
  describing the bug or feature idea;
- Fork the project, make changes, and submit a pull request.
