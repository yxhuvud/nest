.PHONY: test release

test:
	crystal spec -Dpreview_mt -Dexecution_context

release:
	@test -n "$(VERSION)" || (echo "usage: make release VERSION=1.2.3" >&2; exit 1)
	@test "$(VERSION)" = "$$(shards version)" || \
		(echo "VERSION does not match shard.yml: $$(shards version)" >&2; exit 1)
	@case "$(VERSION)" in \
		[0-9]*.[0-9]*.[0-9]*) ;; \
		*) echo "invalid release version: $(VERSION)" >&2; exit 1 ;; \
	esac
	@test -z "$$(git status --porcelain)" || \
		(echo "working tree is not clean" >&2; exit 1)
	git tag -a "v$(VERSION)" -m "v$(VERSION)"
