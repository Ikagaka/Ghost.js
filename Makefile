LIB_SOURCE_DIR = lib
LIB_TARGET_DIR = lib
BIN_SOURCE_DIR = bin
BIN_TARGET_DIR = bin
SOURCE_DIR = src
TARGET_DIR = .
DOC_SOURCE_DIR = doc
DOC_TARGET_DIR = doc
TEST_DIR = test
DOC_TITLE = Ghost.js
LIB_NAME = 
BIN_NAME = 

LIB_SOURCES = $(wildcard $(SOURCE_DIR)/$(LIB_SOURCE_DIR)/*.coffee)
ifeq ("$(LIB_NAME)", "")
LIB_TARGET = $(addprefix $(TARGET_DIR)/$(LIB_TARGET_DIR)/,$(notdir $(LIB_SOURCES:.coffee=.js)))
else
LIB_TARGET = $(TARGET_DIR)/$(LIB_TARGET_DIR)/$(LIB_NAME).js
endif
BIN_SOURCES = $(wildcard $(SOURCE_DIR)/$(BIN_SOURCE_DIR)/*.coffee)
ifeq ("$(BIN_NAME)", "")
BIN_TARGET = $(addprefix $(TARGET_DIR)/$(BIN_TARGET_DIR)/,$(notdir $(BIN_SOURCES:.coffee=.js)))
else
BIN_TARGET = $(TARGET_DIR)/$(BIN_TARGET_DIR)/$(BIN_NAME).js
endif
LIB_TARGET_TO_SOURCE = $(addprefix $(SOURCE_DIR)/$(LIB_SOURCE_DIR)/,$(notdir $(file:.js=.coffee)))
BIN_TARGET_TO_SOURCE = $(addprefix $(SOURCE_DIR)/$(BIN_SOURCE_DIR)/,$(notdir $(file:.js=.coffee)))
DOC_SOURCES = $(wildcard $(SOURCE_DIR)/$(DOC_SOURCE_DIR)/*.coffee)
TEST_SOURCES_COFFEE = $(wildcard $(TEST_DIR)/*.coffee)
TEST_TARGETS_JS = $(TEST_SOURCES_COFFEE:.coffee=.js)
TEST_SOURCES_JADE = $(wildcard $(TEST_DIR)/*.jade)
TEST_TARGETS_HTML = $(TEST_SOURCES_JADE:.jade=.html)

NODE := node
CAT := cat
RM := rm
COFFEE := node_modules/.bin/coffee
JADE := node_modules/.bin/jade
MOCHA := node_modules/.bin/mocha
ifeq ($(OS), Windows_NT)
MOCHA := $(subst /,\,$(MOCHA))
endif
MOCHA_PHANTOMJS := node_modules/.bin/mocha-phantomjs
ISTANBUL := node_modules/.bin/istanbul
ifeq ($(OS), Windows_NT)
ISTANBUL := $(subst /,\,$(ISTANBUL))
endif
CODO := node_modules/.bin/codo
ifeq ($(OS), Windows_NT)
CODO := $(subst /,\,$(CODO))
endif

all: $(LIB_TARGET) $(BIN_TARGET)

clean :
ifeq ($(OS), Windows_NT)
	$(RM) $(subst /,\,$(LIB_TARGET) $(BIN_TARGET) $(TEST_TARGETS_JS) $(TEST_TARGETS_HTML))
else
	$(RM) $(LIB_TARGET) $(BIN_TARGET) $(TEST_TARGETS_JS) $(TEST_TARGETS_HTML)
endif

$(BIN_TARGET): $(BIN_SOURCES)
ifeq ("$(BIN_NAME)", "")
	$(CAT) $(foreach file,$@,$(BIN_TARGET_TO_SOURCE)) | $(COFFEE) -c --stdio > $@
	$(NODE) -e "fs=require('fs');c='#!/usr/bin/env node\n'+fs.readFileSync('$@');fs.writeFileSync('$@', c)"
else
	$(CAT) $^ | $(COFFEE) -c --stdio > $@
	$(NODE) -e "fs=require('fs');c='#!/usr/bin/env node\n'+fs.readFileSync('$@');fs.writeFileSync('$@', c)"
endif

$(LIB_TARGET): $(LIB_SOURCES)
ifeq ("$(LIB_NAME)", "")
	$(CAT) $(foreach file,$@,$(LIB_TARGET_TO_SOURCE)) | $(COFFEE) -c --stdio > $@
else
	$(CAT) $^ | $(COFFEE) -c --stdio > $@
endif

test: $(LIB_TARGET) $(BIN_TARGET) test_node test_browser

test_node: $(TEST_TARGETS_JS)
	$(MOCHA) $(TEST_DIR)

test_browser: $(TEST_TARGETS_HTML) $(TEST_TARGETS_JS)
	$(MOCHA_PHANTOMJS) -R spec $(TEST_DIR)/*.html

cov: $(LIB_TARGET) $(BIN_TARGET) $(TEST_TARGETS_JS)
	$(ISTANBUL) cover node_modules/mocha/bin/_mocha

doc: $(TARGET_DIR)/$(DOC_TARGET_DIR)/index.html

$(TARGET_DIR)/$(DOC_TARGET_DIR)/index.html:  $(LIB_SOURCES) $(DOC_SOURCES)
	$(CODO) --name "$(DOC_TITLE)" --title "$(DOC_TITLE) Documentation" -o $(TARGET_DIR)/$(DOC_TARGET_DIR) $^

.PHONY: test doc

.SUFFIXES: .coffee .js .jade .html

.coffee.js:
	$(CAT) $^ | $(COFFEE) -c --stdio > $@

.jade.html:
	$(CAT) $^ | $(JADE) -P > $@
