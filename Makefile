# Go parameters
GOCMD     = go
GOBUILD   = $(GOCMD) build -v
GOCLEAN   = $(GOCMD) clean -v
GOINSTALL = $(GOCMD) install -v
GOTEST    = $(GOCMD) test
GODEP     = $(GOTEST) -i
GOFMT     = gofmt -w
GOGET     = $(GOCMD) get $(GOGET_FLAGS)
GOLINT    = ${GOLINTDIR}/bin/golangci-lint
GOCOV     = gocov
DOCKER    = docker
DCOMPOSE  = docker-compose

SOURCEDIR = .
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
BUILDDIR = build
BINDIR = bin
DISTRDIR = $(BUILDDIR)/distr

GOLINTDIR            ?= $(GOPATH)
GOLINTFLAGS           =
GOLINTER_SUPPRESS_ERR =

GOCOV_COVER_XML=$(BUILDDIR)/gocov/coverage.xml
GOCOV_COVER_HTML=$(BUILDDIR)/gocov/coverage.html

VERSION      := v1.0.0
BUILD_TIME   := $(shell date +%FT%T%z)
# this variables should be set by a builder
BUILD_COMMIT := ${BUILD_COMMIT}
BUILD_BRANCH := ${BUILD_BRANCH}

PKGS = github.com/cured-plumbum/fretsaw/cmd/fsaw
COPY_FILES = 

LDFLAGS	= -ldflags "-X main.buildVersion=${VERSION}  -X main.buildTime=${BUILD_TIME} -X main.buildCommit=${BUILD_COMMIT} -X main.buildBranch=${BUILD_BRANCH}"
TESTFLAGS = -race -timeout 5m

.phony: $(GOCOV)
$(GOCOV):
	GO111MODULE=off $(GOGET) github.com/axw/gocov/gocov
	GO111MODULE=off $(GOGET) github.com/axw/gocov/...
	GO111MODULE=off $(GOGET) github.com/AlekSi/gocov-xml
	GO111MODULE=off $(GOGET) gopkg.in/matm/v1/gocov-html

# https://github.com/golangci/golangci-lint#install
# curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s v1.15.0

.phony: lint-install
lint-install: $(GOLINT)

$(GOLINT):
	mkdir -p $(GOLINTDIR)
	cd $(GOLINTDIR) && curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s v1.15.0

.phony: lint 
lint: download lint-install
	GO111MODULE=on $(GOLINT) $(GOLINTFLAGS) run;$(GOLINTER_SUPPRESS_ERR)

.phony: download
download:
	$(GOCMD) mod download

.phony: clean 
clean:
	go clean
	if [ -d $(BUILDDIR) ] ; then rm -rf $(BUILDDIR) ; fi
	if [ -d $(BINDIR) ] ; then rm -rf $(BINDIR) ; fi

.phony: test 
test:
	$(GOTEST) $(TESTFLAGS) ./...

build: $(SOURCES) $(PKGS)

# CGO disabled for remove dynamic dependencies
.phony: $(PKGS) 
$(PKGS):
	$(eval PKG := $@)
	$(eval OUT := $(notdir $@))
	env CGO_ENABLED=0 $(GOBUILD) $(LDFLAGS) -installsuffix cgo -o $(BINDIR)/$(OUT) $(PKG)

.phony: install
install: $(SOURCES)
	$(foreach PKG, $(PKGS), $(GOINSTALL) $(LDFLAGS) $(PKG);)

.phony: distr
distr: build $(COPY_FILES)

.phony: generate
generate:
	GO111MODULE=off $(GOGET) golang.org/x/tools/cmd/stringer
	$(GOCMD) generate ./...

.phony: $(COPY_FILES)
$(COPY_FILES):
	mkdir -p $(DISTRDIR)
	cp $@ $(DISTRDIR)/

.phony: info
info:
	env
	go version
	go env

gocov-report: $(GOCOV) download
	$(GOCOV) test $(TESTFLAGS) ./...  | $(GOCOV) report

gocov-xml: $(GOCOV) download
	mkdir -p $(dir $(GOCOV_COVER_XML))
	$(GOCOV) test $(TESTFLAGS) ./...  | gocov-xml > $(GOCOV_COVER_XML)

gocov-html: $(GOCOV) download
	mkdir -p $(dir $(GOCOV_COVER_HTML))
	$(GOCOV) test $(TESTFLAGS) ./...  | gocov-html > $(GOCOV_COVER_HTML)
