FORMS=terms proposal
FORMATS=json html docx pdf
TARGETS=$(foreach form,$(FORMS),$(foreach format,$(FORMATS),$(addsuffix .$(format),$(form))))

CF=node_modules/.bin/commonform
MDTOCF=node_modules/.bin/commonmark-to-commonform

all: $(TARGETS)

%.json: %.md | $(MDTOCF)
	$(MDTOCF) < $< > $@

%.html: %.json %.title | $(CF)
	$(CF) render -f html5 --title "$(shell cat $*.title)" --blanks blanks.json --signatures signatures.json --ordered-lists $< > $@

%.docx: %.json %.title | $(CF)
	$(CF) render -f docx --title "$(shell cat $*.title)" --blanks blanks.json --signatures signatures.json --number outline --left-align-title --indent-margins --styles styles.json $< > $@

%.pdf: %.docx
	unoconv $<

$(MDTOCF) $(CF):
	npm install
