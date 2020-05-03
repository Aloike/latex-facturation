LATEX=pdflatex

all: world clean

clean:
	rm -rf factures/*.log factures/*.aux factures/*.out

flush:
	rm -rf factures/*.pdf

world: *.pdf

%.pdf: %.tex
	$(LATEX) --output-directory=factures $<

