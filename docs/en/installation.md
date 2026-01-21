---
title: Installation and Packages
---

# Installation and packaging

This guide describes how to install the **Cognitive GitOps Suite** on your
machine and how to generate a Debian package (`.deb`) to deploy the suite in
Ubuntu or Debian-based environments. The instructions here complement the
project [README](https://github.com/atlantyde-labs/cognitive-suite/blob/main/README.md) and are part of the documentation published on
GitHub Pages.

## Development installation

To run the suite in development mode without containers or prebuilt packages,
follow these steps on your machine:

1. Clone or download the suite repository.
2. Ensure Python 3.8+ and `pip` are installed.
3. Run `python cogctl.py init` to create the required folders under `data/`
   and `outputs/`.
4. Copy the files you want to analyze into `data/input/`.
5. Run `python cogctl.py ingest <path/to/file>` to convert the document to
   text.
6. Launch the analysis with `python cogctl.py analyze`. Results will be stored
   in `outputs/insights/analysis.json`.

## Debian package generation

The suite includes a helper script to package all components into a `.deb`
file. This makes distribution and installation easier on development machines
where Docker is not desired. The script lives at `scripts/build-deb.sh`.

### Build

1. Ensure packaging tools are installed. On Debian/Ubuntu systems install them
   with `sudo apt install dpkg-dev`.
2. Run the script with the version you want to assign to the package, for
   example:

   ```bash
   ./scripts/build-deb.sh 0.1.0
   ```

   The script creates a temporary tree under `tmp/`, copies the suite files to
   `/usr/local/lib/cognitive-suite`, generates an executable wrapper `cogctl`
   in `/usr/local/bin`, and builds the package in `dist/` as
   `cognitive-suite_<version>_all.deb`.

### Install

To install the generated package on your machine:

```bash
sudo apt install ./dist/cognitive-suite_0.1.0_all.deb
```

This installs the suite under `/usr/local/lib/cognitive-suite` and registers
`cogctl` in the system PATH. You can run the CLI with `cogctl` from any
folder. To remove it, use `sudo apt remove cognitive-suite`.

## GitHub Pages publication

The contents of the `docs/` folder are automatically published as a static
site via GitHub Pages. The workflow defined in
`.github/workflows/deploy-pages.yml` runs whenever documentation files are
updated. Once deployed, you can browse the site at
`https://<user>.github.io/<repository>/` and consult guides, diagrams, and
internal references. Add your own pages under `docs/` to expand the suite's
public documentation.
