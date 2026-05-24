MAIN_TEX := Main.tex
MAIN_BASENAME := $(basename $(MAIN_TEX))
OUTDIR ?= build
PDF := $(OUTDIR)/$(MAIN_BASENAME).pdf
DEPS := $(OUTDIR)/$(MAIN_BASENAME).d
SOURCE_ARCHIVE := $(OUTDIR)/$(MAIN_BASENAME)-source.tar.gz
LATEXMK := latexmk
LATEXMK_FLAGS := -xelatex -shell-escape -interaction=nonstopmode -halt-on-error -file-line-error -outdir=$(OUTDIR) -M -MP -MF $(DEPS)

-include $(DEPS)

.PHONY: all pdf watch clean distclean pack notsure

all: pdf

$(OUTDIR):
	mkdir -p $(OUTDIR)

pdf: $(PDF)

$(PDF): $(MAIN_TEX) | $(OUTDIR)
	$(LATEXMK) $(LATEXMK_FLAGS) $(MAIN_TEX)
	test -f $(PDF)
	touch $(PDF)

watch: | $(OUTDIR)
	$(LATEXMK) $(LATEXMK_FLAGS) -pvc -view=none $(MAIN_TEX)

pack: | $(OUTDIR)
	tar -czf $(SOURCE_ARCHIVE) \
		$(MAIN_TEX) \
		README.txt \
		ReadmeByDavidFrisk.pdf \
		prerequisites.sh \
		$(wildcard refs.bib) \
		include \
		figure

notsure:
	@if command -v rg >/dev/null 2>&1; then \
		rg -n "NOTSURE:|TODO:" sections_drafts Main.tex include ../agents/orchestrator/reviews || true; \
	else \
		grep -rnE "NOTSURE:|TODO:" sections_drafts Main.tex include ../agents/orchestrator/reviews || true; \
	fi

clean:
	if [ -d "$(OUTDIR)" ]; then $(LATEXMK) -c -outdir=$(OUTDIR) $(MAIN_TEX); fi

distclean:
	if [ -d "$(OUTDIR)" ]; then $(LATEXMK) -C -outdir=$(OUTDIR) $(MAIN_TEX); fi
	rm -rf $(OUTDIR)
