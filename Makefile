LATEX=pdflatex
LATEX_OPTIONS:=-halt-on-error -interaction=nonstopmode --output-directory=factures


all: world clean

clean:
	rm -rf factures/*.log factures/*.aux factures/*.out

flush:
	rm -rf factures/*.pdf

world: *.pdf

%.pdf: %.tex
	$(LATEX) $(LATEX_OPTIONS) $<
	$(LATEX) $(LATEX_OPTIONS) $<
