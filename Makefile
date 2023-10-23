MINTRUN = mint run
DOCC_TARGET = SimplexArchitecture
DOCC_DIR = ./docs

.PHONY: bootstrap
format:
	mint bootstrap

.PHONY: format
format:
	$(MINTRUN) swiftformat .

.PHONY: test
test:
	swift test -v

.PHONY: benchmark
benchmark:
	swift run --configuration release swiftui-simplex-architecture-benchmark

.PHONY: docc
docc:
	swift package --allow-writing-to-directory $(DOCC_DIR) \
		generate-documentation --target $(DOCC_TARGET) \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path swiftui-simplex-architecture \
		--output-path $(DOCC_DIR) 

.PHONY: docc-preview
docc-preview:
	swift package --disable-sandbox preview-documentation --target $(DOCC_TARGET)
