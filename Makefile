.PHONY: help prepare-ios-for-release run-debug rd prepare prep build-android-release bar build-ios-release bir test t analyze a bump release rel

.DEFAULT_GOAL := help

ANDROID_RELEASE_BUNDLE := build/app/outputs/bundle/release/app-release.aab
APP_CHECK_DEBUG_CONFIG := env/app_check.debug.local.json

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

help: ## Show available Make commands.
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / { printf "  %-24s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

run-debug: ## Run with debug config and persistent local App Check tokens.
	@if [ ! -f "$(APP_CHECK_DEBUG_CONFIG)" ]; then \
		echo "Missing $(APP_CHECK_DEBUG_CONFIG). Copy env/app_check.debug.local.example.json and add registered UUIDv4 tokens." >&2; \
		exit 1; \
	fi
	fvm flutter run --dart-define-from-file=env/app_config.debug.json --dart-define-from-file=$(APP_CHECK_DEBUG_CONFIG)

rd: run-debug ## Alias for run-debug.

# Generates iOS release config only.
# Then you need to open Xcode and build/archive manually.
prepare-ios-for-release: ## Generate iOS release config for a manual Xcode archive.
	fvm flutter build ios --config-only --release --dart-define-from-file=env/app_config.prod.json

prep: test prepare-ios-for-release ## Run the test suite, then generate the iOS release config.

build-android-release: ## Build the Android release App Bundle (.aab).
	fvm flutter build appbundle --release --dart-define-from-file=env/app_config.prod.json

bar: build-android-release ## Build the Android release bundle and reveal it in Finder.
	@if [ -f "$(ANDROID_RELEASE_BUNDLE)" ]; then \
		open -R "$(ANDROID_RELEASE_BUNDLE)"; \
	else \
		echo "Expected bundle not found: $(ANDROID_RELEASE_BUNDLE)" >&2; \
		exit 1; \
	fi

test: ## Run all tests (app + every package under packages/).
	fvm flutter test
	@for pkg in packages/*/; do \
		if [ -d "$${pkg}test" ]; then \
			echo "==> Testing $$pkg"; \
			( cd "$$pkg" && fvm flutter test ) || exit 1; \
		fi; \
	done

t: test ## Alias for test.

analyze: ## Run static analysis.
	fvm flutter analyze

a: analyze ## Alias for analyze.

bump: ## Bump version, commit it, and create a local tag. Usage: make bump 1.2.0 [BUILD=7]
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
