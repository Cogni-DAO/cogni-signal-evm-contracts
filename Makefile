# Development Chain Setup
# Requires: DEV_WALLET_PRIVATE_KEY and RPC_URL environment variables

.PHONY: dao-setup deploy-contract
dao-setup:
	@echo "Deploying complete development stack: ERC20 → DAO → CogniSignal"
	@echo "Checking required environment variables..."
	@test -n "$(DEV_WALLET_PRIVATE_KEY)" || (echo "❌ DEV_WALLET_PRIVATE_KEY not set" && exit 1)
	@test -n "$(RPC_URL)" || (echo "❌ RPC_URL not set" && exit 1)
	@echo "✅ Environment variables set"
	forge script script/SetupDevChain.s.sol:SetupDevChain --rpc-url $(RPC_URL) --broadcast

deploy-contract:
	@echo "Deploying CogniSignal contract with existing DAO"
	@echo "Checking required environment variables..."
	@test -n "$(DEV_WALLET_PRIVATE_KEY)" || (echo "❌ DEV_WALLET_PRIVATE_KEY not set" && exit 1)
	@test -n "$(RPC_URL)" || (echo "❌ RPC_URL not set" && exit 1)
	@test -n "$(DAO_ADDRESS)" || (echo "❌ DAO_ADDRESS not set" && exit 1)
	@echo "✅ Environment variables set"
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL) --broadcast