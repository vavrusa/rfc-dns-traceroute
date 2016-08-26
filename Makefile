MMARK = mmark
XML2RFC = xml2rfc

all: draft.txt
publish: draft.html
	cp $< index.html
clean:
	rm -f *.xml *.txt *.html

%.xml: %.md
	$(MMARK) -xml2 -page $< > $@
%.txt: %.xml
	$(XML2RFC) --text $<
%.html: %.xml
	$(XML2RFC) --html $<

.PHONY: all clean publish
