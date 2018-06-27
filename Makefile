PATH  := node_modules/.bin:$(PATH)
SHELL := /bin/bash
.DEFAULT_GOAL := all
.PHONY: all clean deps help installIfNot

##
## Sources
##

sourceElm        := src/%.elm
sourceJs         := src/%.js
allElm           := src/*.elm
allJs            := src/*.js
debugDist        := dist/%.js
debugElmDist     := dist/%.elm.js
browserifyDist   := dist/%.bdl.js
productionDist   := dist/%.min.js
optimizedElmDist := dist/%.elm.min.js

##
## Files dependencies & build
##

$(debugElmDist): $(sourceElm) $(allElm)
	$(call stl, $*, "Compiling")
	./bin/elm make $< --output=$@

$(optimizedElmDist): $(debugElmDist)
	$(call stl, $*, "Optimizing")
	./bin/elm make src/$*.elm --optimize --output=$@

$(debugDist): $(debugElmDist) $(browserifyDist)
	$(call stl, $*, "Concatenating")
	cat $^ > $@

$(browserifyDist): $(sourceJs) $(allJs)
	$(call stl, $*, "Bundling")
	browserify $< -o $@

$(productionDist): $(optimizedElmDist) $(browserifyDist)
	$(call stl, $*, "Minifying")
	uglifyjs $^ -cm -o $@


##
## Commands
##

all: clean deps dist

dist: dist/Private.min.js dist/Public.min.js

debug: dist/Private.js dist/Public.js

watch:
	$(call action, "Watching...")
	@ livereload dist/ \
		& chokidar 'src/**.elm' --initial -c 'make -s debug'


##
## Npm dependencies
##

npmBinDeps := browserify livereload

$(npmBinDeps):
	@ make -s installIfNot cmd=$@ npm=$@

# uglifyjs & chokidar have different npm id and command
uglifyjs:
	@ make -s installIfNot cmd=uglifyjs npm=uglify-js

chokidar:
	@ make -s installIfNot cmd=chokidar npm=chokidar-cli

# This Makefile requires some bins
deps: $(npmBinDeps) uglifyjs chokidar
	# Also, if package-lock is older than package, we update npm
	@ if [ package-lock.json -ot package.json ]; then npm i; fi
	$(call success, "All dependencies fetched")

installIfNot:
ifeq ($(shell command -v $(cmd) 2>&1 /dev/null),)
	$(call stl, $(npm), "Installing")
	@ npm i -D $(npm)
endif

clean:
	@ rm -rf dist elm-stuff node_modules
	$(call success, "Cleaned")

distclean:
	@ rm -rf dist
	$(call success, "Cleaned dist")


##
## Help & Formatting
##

help:
	$(call success, "Build the front")
	$(call help, "dist   ","build files for production")
	$(call help, "debug  ","build files for debug")
	@ echo ""
	$(call help, "clean  ","remove temporary files")
	$(call help, "watch  ","watch & compile files")
	$(call help, "deps   ","install dependencies")
	$(call help, "help   ","this")
	@ echo ""
	@ echo ""

define stl
	@ echo ""
	@ tput setaf 3
	@ tput bold
	@ echo -n ":"
	@ tput setaf 6
	@ echo -n $2
	@ tput setaf 3
	@ echo -n ":"
	@ echo -n $1
	@ tput sgr0
	@ echo ""
endef

define success
	@ echo ""
	@ echo -n "  "
	@ tput bold
	@ tput setaf 2
	@ echo -n $1
	@ tput sgr0
	@ echo ""
	@ echo ""
endef

define action
	@ echo ""
	@ echo -n "  "
	@ tput bold
	@ tput setaf 6
	@ echo -n $1
	@ tput sgr0
	@ echo ""
	@ echo ""
endef

define help
	@ echo ""
	@ echo -n " > "
	@ tput bold
	@ tput setaf 6
	@ echo -n $1
	@ tput sgr0
	@ echo -n " : "
	@ echo -n $2
endef

