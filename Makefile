# Go parameters
GOCMD     = go
GOBUILD   = $(GOCMD) build -v
GOCLEAN   = $(GOCMD) clean -v
GOINSTALL = $(GOCMD) install -v
GOTEST    = $(GOCMD) test
GODEP     = $(GOTEST) -i
GOFMT     = gofmt -w
GOGET     = $(GOCMD) get -v
GOLINT    = gometalinter
GOCOV     = gocov

SOURCEDIR = .
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
BUILDDIR = build
DISTRDIR = $(BUILDDIR)/distr

GOLINTFLAGS=--deadline=300s -t --vendored-linters --concurrency=4
CHECKSTYLE_FILE=$(BUILDDIR)/gometalinter/checkstyle-result.xml
GOLINTER_SUPPRESS_ERR=

GOCOV_COVER_XML=$(BUILDDIR)/gocov/coverage.xml

VERSION      := v1.0.0
BUILD_TIME   := $(shell date +%FT%T%z)
# this variables should be set by a builder
BUILD_COMMIT := ${BUILD_COMMIT}
BUILD_BRANCH := ${BUILD_BRANCH}

PKGS = github.com/cured-plumbum/fretsaw/fsaw
COPY_FILES = 

DEPS = 	github.com/stretchr/testify/assert\
		github.com/stretchr/testify/require\
		github.com/sirupsen/logrus\
		github.com/spf13/cobra\
		github.com/spf13/viper\
		github.com/mitchellh/go-homedir\
		github.com/jroimartin/gocui\


LDFLAGS	= -ldflags "-X $(PKG)/cmd.buildVersion=${VERSION}  -X $(PKG)/cmd.buildTime=${BUILD_TIME} -X $(PKG)/cmd.buildCommit=${BUILD_COMMIT} -X $(PKG)/cmd.buildBranch=${BUILD_BRANCH}"

.phony: $(GOLINT) 
$(GOLINT):
	$(GOGET) -u github.com/alecthomas/gometalinter
	$(GOLINT) --install --vendored-linters

.phony: $(GOCOV)
$(GOCOV):
	$(GOGET) -u github.com/axw/gocov/gocov
	$(GOGET) -u github.com/axw/gocov/...
	$(GOGET) -u github.com/AlekSi/gocov-xml

.phony: lint 
lint: deps
	$(GOLINT) $(GOLINTFLAGS) ./...;$(GOLINTER_SUPPRESS_ERR)

.phony: lint-checkstyle
lint-checkstyle: deps
	mkdir -p $(dir $(CHECKSTYLE_FILE))
	$(GOLINT) $(GOLINTFLAGS) --checkstyle ./... > $(CHECKSTYLE_FILE);$(GOLINTER_SUPPRESS_ERR)

.phony: clean 
clean:
	go clean
	if [ -d $(BUILDDIR) ] ; then rm -rf $(BUILDDIR) ; fi

.phony: test 
test: deps
	$(GOTEST) -race ./...

.phony: deps
deps: $(DEPS)

$(DEPS):
	$(GOGET) -t $@

build: $(SOURCES) deps $(PKGS)

.phony: $(PKGS) 
$(PKGS):
	$(eval PKG := $@)
	$(eval OUT := $(notdir $@))
	$(GOBUILD) $(LDFLAGS) -o $(DISTRDIR)/$(OUT) $(PKG)

.phony: install
install: $(SOURCES) deps
	$(foreach PKG, $(PKGS), $(GOINSTALL) $(LDFLAGS) $(PKG);)

.phony: distr
distr: build $(COPY_FILES)

.phony: $(COPY_FILES)
$(COPY_FILES):
	mkdir -p $(DISTRDIR)
	cp $@ $(DISTRDIR)/

.phony: info
info:
	env
	go version
	go env

gocov-report: $(GOCOV) deps
	$(GOCOV) test -race ./... | $(GOCOV) report

gocov-cover-xml: $(GOCOV) deps
	mkdir -p $(dir $(GOCOV_COVER_XML))
	$(GOCOV) test -race ./... | gocov-xml > $(GOCOV_COVER_XML)
