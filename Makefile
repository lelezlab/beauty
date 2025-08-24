all: bootstrap models supabase-deploy build-sim proof-sim share
	@echo OK: share at ~/Documents/share/beauty-share-*.zip

.PHONY: bootstrap models supabase-deploy build-sim proof-sim share
share-pack:
	bash scripts/share_pack.sh


