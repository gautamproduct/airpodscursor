.PHONY: build app run install test icon release clean

build:
	swift build

test:
	swift test

icon:
	swift scripts/make-icon.swift "$(CURDIR)"

app:
	scripts/build-app.sh

# Fast single-arch build, then launch.
run:
	ARCHS=arm64 scripts/build-app.sh
	open build/AirPodsCursor.app

# Installing to /Applications keeps the Accessibility grant stable and enables Launch at Login.
install: app
	rm -rf /Applications/AirPodsCursor.app
	cp -R build/AirPodsCursor.app /Applications/
	open /Applications/AirPodsCursor.app

release:
	scripts/release.sh

clean:
	rm -rf .build build
