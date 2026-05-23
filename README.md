# Master Thesis

This repository is the working area for converting the completed NanoMem
research project into a Chalmers master's thesis.

## Layout

- `agents/`: context and planning documents for agent-assisted writing.
- `paper/`: Chalmers LaTeX thesis template, thesis source, figures, references,
  and local build configuration.
- `paper/include/`: thesis chapters, front matter, back matter, and settings.
- `paper/figure/`: thesis figures and template assets.
- `paper/build/`: generated LaTeX build artifacts and compiled PDF. This
  directory is ignored and can be regenerated.

The source NanoMem project is outside this repository:

```text
/mnt/models/yupan/llm/nanomem
```

The source NeurIPS paper is:

```text
/mnt/models/yupan/llm/nanomem/paper
```

Read `agents/contexts.md` before making substantive thesis edits.

## Build

Install LaTeX prerequisites when needed:

```bash
cd paper
./prerequisites.sh
```

Compile the thesis:

```bash
cd paper
make pdf
```

The generated PDF is:

```text
paper/build/Main.pdf
```

Useful maintenance commands:

```bash
cd paper
make watch
make clean
make distclean
make pack
```

## Writing Workflow

1. Read `agents/contexts.md`.
2. Inspect the relevant NanoMem paper sections and source files.
3. Edit thesis files under `paper/include/`.
4. Compile with `make pdf`.
5. Fix LaTeX errors before continuing to the next writing task.
