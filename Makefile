CFCM=node_modules/.bin/commonform-commonmark
CFDOCX=node_modules/.bin/commonform-docx
CRITIQUE=node_modules/.bin/commonform-critique
JSON=node_modules/.bin/json
LINT=node_modules/.bin/commonform-lint
MUSTACHE=node_modules/.bin/mustache
TOOLS=$(CFCM) $(CFDOCX) $(CRITIQUE) $(JSON) $(LINT) $(MUSTACHE)

BUILD=build
BASENAMES=terms proposal
FORMS=$(addsuffix .form.json,$(addprefix $(BUILD)/,$(BASENAMES)))

GIT_TAG=$(shell (git diff-index --quiet HEAD && git describe --exact-match --tags 2>/dev/null | sed 's/v//'))
EDITION:=$(or $(EDITION),$(if $(GIT_TAG),$(GIT_TAG),Internal Draft))
EDITION_FLAG=--edition "$(EDITION)"

all: docx pdf md

docx: $(addprefix $(BUILD)/,$(BASENAMES:=.docx))
pdf: $(addprefix $(BUILD)/,$(BASENAMES:=.pdf))
md: $(addprefix $(BUILD)/,$(BASENAMES:=.md))

$(BUILD)/%.docx: $(BUILD)/%.form.json $(BUILD)/%.directions.json %.title blanks.json %.json styles.json | $(CFDOCX) $(BUILD)
	$(CFDOCX) --title "$(shell cat $*.title)" --edition "$(EDITION)" --number outline --indent-margins --left-align-title --values blanks.json --directions $(BUILD)/$*.directions.json --styles styles.json --signatures $*.json $< > $@

$(BUILD)/%.form.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse --only form < $< > $@

$(BUILD)/%.directions.json: %.md | $(BUILD) $(CFCM)
	$(CFCM) parse --only directions < $< > $@

%.pdf: %.docx
	unoconv $<

$(BUILD):
	mkdir -p $@

$(TOOLS):
	npm ci

.PHONY: clean docker lint critique

lint: $(FORMS) | $(LINT) $(JSON)
	@for form in $(FORMS); do \
		echo ; \
		echo $$form; \
		cat $$form | $(LINT) | $(JSON) -a message | sort -u; \
	done; \

critique: $(FORMS) | $(CRITIQUE) $(JSON)
	@for form in $(FORMS); do \
		echo ; \
		echo $$form ; \
		cat $$form | $(CRITIQUE) | $(JSON) -a message | sort -u; \
	done

clean:
	rm -rf $(BUILD)

docker:
	docker build -t open-dev-time-block-terms .
	docker run --name open-dev-time-block-terms open-dev-time-block-terms
	docker cp open-dev-time-block-terms:/workdir/$(BUILD) .
	docker rm open-dev-time-block-terms
