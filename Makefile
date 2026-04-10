.PHONY: run-debug rd prepare prep build-android-release bar build-ios-release bir test t analyze a bump release rel

# Allows: make bump 1.5.1 [BUILD=20]
# It maps the positional argument to VERSION and ignores it as a make target.
ifneq ($(filter bump,$(MAKECMDGOALS)),)
VERSION := $(word 2,$(MAKECMDGOALS))
ifneq ($(strip $(VERSION)),)
.PHONY: $(VERSION)
$(VERSION):
	@:
endif
endif

## Run app with debug config.
run-debug:
	flutter run --dart-define-from-file=env/app_config.debug.json

## Alias for run-debug.
rd: run-debug

# Generates iOS release config only.
# Then you need to open Xcode and build/archive manually.
prepare:
	flutter build ios --config-only --release --dart-define-from-file=env/app_config.prod.json

## Alias for prepare.
prep: prepare

## Build Android App Bundle for release.
build-android-release:
	flutter build appbundle --release --dart-define-from-file=env/app_config.prod.json

## Alias for build-android-release.
bar: build-android-release

## Build iOS IPA for release.
build-ios-release:
	flutter build ipa --release --dart-define-from-file=env/app_config.prod.json

## Alias for build-ios-release.
bir: build-ios-release

## Run Flutter test suite.
test:
	flutter test

## Alias for test.
t: test

## Run static analysis.
analyze:
	flutter analyze

## Alias for analyze.
a: analyze

## Bump version, commit, and create a local tag (no push).
bump:
ifndef VERSION
	$(error Usage: make bump 1.2.0 [BUILD=7])
endif
	@set -eu; \
	if ! printf '%s' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Error: VERSION must match x.y.z (example: 1.2.0)" >&2; \
		exit 1; \
	fi; \
	if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "Error: git working tree is not clean. Commit or stash changes first." >&2; \
		exit 1; \
	fi; \
	current_version="$$(awk '/^version:[[:space:]]*/{print $$2; exit}' pubspec.yaml)"; \
	if [ -z "$$current_version" ]; then \
		echo "Error: failed to read current pubspec version" >&2; \
		exit 1; \
	fi; \
	build="$(strip $(BUILD))"; \
	if [ -z "$$build" ]; then \
		current_build=0; \
		case "$$current_version" in \
			*+*) current_build="$${current_version##*+}" ;; \
		esac; \
		case "$$current_build" in \
			''|*[!0-9]*) echo "Error: current build number is invalid in pubspec.yaml" >&2; exit 1 ;; \
		esac; \
		build=$$((current_build + 1)); \
	else \
		case "$$build" in \
			''|*[!0-9]*) echo "Error: BUILD must be an integer" >&2; exit 1 ;; \
		esac; \
	fi; \
	new_version="$(VERSION)+$$build"; \
	tag="v$(VERSION)"; \
	if git rev-parse -q --verify "refs/tags/$$tag" >/dev/null; then \
		echo "Error: tag $$tag already exists" >&2; \
		exit 1; \
	fi; \
	tmp_file="$$(mktemp)"; \
	awk -v new_version="$$new_version" 'BEGIN { replaced = 0 } /^version:[[:space:]]*/ && replaced == 0 { print "version: " new_version; replaced = 1; next } { print } END { if (replaced == 0) exit 2 }' pubspec.yaml > "$$tmp_file"; \
	mv "$$tmp_file" pubspec.yaml; \
	git add pubspec.yaml; \
	git commit -m "chore: bump app version to $(VERSION)"; \
	git tag -a "$$tag" -m "Release $$tag"; \
	echo "Bumped to $$new_version, committed, and tagged $$tag"

## Bump version, commit, tag, and push commit + tag.
release:
ifndef VERSION
	$(error Usage: make release VERSION=1.2.0 [BUILD=7])
endif
	@set -eu; \
	if ! printf '%s' "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Error: VERSION must match x.y.z (example: 1.2.0)" >&2; \
		exit 1; \
	fi; \
	if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "Error: git working tree is not clean. Commit or stash changes first." >&2; \
		exit 1; \
	fi; \
	current_version="$$(awk '/^version:[[:space:]]*/{print $$2; exit}' pubspec.yaml)"; \
	if [ -z "$$current_version" ]; then \
		echo "Error: failed to read current pubspec version" >&2; \
		exit 1; \
	fi; \
	build="$(strip $(BUILD))"; \
	if [ -z "$$build" ]; then \
		current_build=0; \
		case "$$current_version" in \
			*+*) current_build="$${current_version##*+}" ;; \
		esac; \
		case "$$current_build" in \
			''|*[!0-9]*) echo "Error: current build number is invalid in pubspec.yaml" >&2; exit 1 ;; \
		esac; \
		build=$$((current_build + 1)); \
	else \
		case "$$build" in \
			''|*[!0-9]*) echo "Error: BUILD must be an integer" >&2; exit 1 ;; \
		esac; \
	fi; \
	new_version="$(VERSION)+$$build"; \
	tag="v$(VERSION)"; \
	if git rev-parse -q --verify "refs/tags/$$tag" >/dev/null; then \
		echo "Error: tag $$tag already exists" >&2; \
		exit 1; \
	fi; \
	tmp_file="$$(mktemp)"; \
	awk -v new_version="$$new_version" 'BEGIN { replaced = 0 } /^version:[[:space:]]*/ && replaced == 0 { print "version: " new_version; replaced = 1; next } { print } END { if (replaced == 0) exit 2 }' pubspec.yaml > "$$tmp_file"; \
	mv "$$tmp_file" pubspec.yaml; \
	git add pubspec.yaml; \
	git commit -m "chore: bump app version to $(VERSION)"; \
	git tag -a "$$tag" -m "Release $$tag"; \
	git push; \
	git push origin "$$tag"; \
	echo "Released $$new_version and pushed $$tag"

## Alias for release.
rel: release
