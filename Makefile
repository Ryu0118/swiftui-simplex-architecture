MINTRUN = mint run

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
