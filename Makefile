SCHEME  = Pulse
PROJECT = Pulse.xcodeproj

.PHONY: all setup generate open build clean convex-dev convex-deploy

all: generate open

setup:
	@which xcodegen  > /dev/null 2>&1 || brew install xcodegen
	@which xcbeautify > /dev/null 2>&1 || brew install xcbeautify

generate: setup
	xcodegen generate

open: generate
	open $(PROJECT)

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Debug build | xcbeautify

clean:
	rm -rf $(PROJECT)
	rm -rf build/

convex-dev:
	cd convex && npx convex dev

convex-deploy:
	cd convex && npx convex deploy
