MINTRUN = mint run

.PHONY: bootstrap
format:
	mint bootstrap

.PHONY: format
format:
	$(MINTRUN) swiftformat .
	