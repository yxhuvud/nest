.PHONY: test

test:
	crystal spec -Dpreview_mt -Dexecution_context
