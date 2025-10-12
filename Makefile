# Development Chain Setup
# Foundry automatically loads .env file for forge commands
# Makefile sources .env to access variables for validation

include .env
export

.PHONY: dao-setup deploy-contract
dao-setup:
	@echo "Deploying complete development stack: ERC20 → DAO → CogniSignal"
	@echo "Checking required environment variables..."
	@test -n "$(DEV_WALLET_PRIVATE_KEY)" || (echo "❌ DEV_WALLET_PRIVATE_KEY not set in .env" && exit 1)
	@test -n "$(RPC_URL)" || (echo "❌ RPC_URL not set in .env" && exit 1)
	@echo "✅ Environment variables loaded from .env"
	forge script script/SetupDevChain.s.sol:SetupDevChain --rpc-url $(RPC_URL) --broadcast

deploy-contract:
	@echo "Deploying CogniSignal contract with existing DAO"
	@echo "Checking required environment variables..."
	@test -n "$(DEV_WALLET_PRIVATE_KEY)" || (echo "❌ DEV_WALLET_PRIVATE_KEY not set in .env" && exit 1)
	@test -n "$(RPC_URL)" || (echo "❌ RPC_URL not set in .env" && exit 1)
	@test -n "$(DAO_ADDRESS)" || (echo "❌ DAO_ADDRESS not set in .env" && exit 1)
	@echo "✅ Environment variables loaded from .env"
	forge script script/Deploy.s.sol:Deploy --rpc-url $(RPC_URL) --broadcast