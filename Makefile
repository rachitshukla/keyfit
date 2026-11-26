APP := KeyFit.app
PLIST := $(APP)/Contents/Info.plist
ICON := $(APP)/Contents/Resources/KeyFit.icns
BIN := $(APP)/Contents/MacOS/KeyFit
STAMP := build/signed
CFLAGS := -Os -fobjc-arc -Wall -Wextra -Wno-unused-parameter -mmacosx-version-min=12.0
ARCHS := -arch arm64 -arch x86_64
FRAMEWORKS := -framework AppKit -framework Carbon -framework ApplicationServices

.PHONY: all test package
all: $(STAMP)

$(BIN): KeyFit.m Layout.h PermissionSetup.m PermissionSetup.h Makefile
	mkdir -p "$(@D)"
	xcrun clang $(CFLAGS) $(ARCHS) -Wl,-dead_strip -o "$@" KeyFit.m PermissionSetup.m $(FRAMEWORKS)
	xcrun strip -x "$@"

$(PLIST): Info.plist
	mkdir -p "$(@D)"
	cp "$<" "$@"

$(ICON): assets/KeyFit.png scripts/make-icon.sh
	mkdir -p "$(@D)"
	sh scripts/make-icon.sh "$<" "$@"

$(STAMP): $(BIN) $(PLIST) $(ICON)
	mkdir -p "$(@D)"
	codesign --force --sign - "$(APP)"
	codesign --verify --strict --all-architectures "$(APP)"
	touch "$@"

build/test-layout: tests/layout.m Layout.h Makefile
	mkdir -p "$(@D)"
	xcrun clang $(CFLAGS) $(ARCHS) -o "$@" "$<" -framework AppKit

build/test-permission: tests/permission.m PermissionSetup.m PermissionSetup.h Makefile
	mkdir -p "$(@D)"
	xcrun clang $(CFLAGS) $(ARCHS) -o "$@" "$<" PermissionSetup.m $(FRAMEWORKS)

test: all build/test-layout build/test-permission
	xcrun lipo "$(BIN)" -verify_arch arm64 x86_64
	plutil -lint "$(PLIST)"
	codesign --verify --strict --all-architectures "$(APP)"
	./build/test-layout
	./build/test-permission

package: test
	ditto -c -k --keepParent --norsrc "$(APP)" build/KeyFit-universal.zip
