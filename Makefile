# Development Chain Setup
# Foundry automatically loads .env file for forge commands
# Makefile sources .env to access variables for validation

include .env
export

.PHONY: dao-setup deploy-contract
dao-setup:
	@echo "Deploying complete development stack: ERC20 → DAO → CogniSignal"
	@echo "Checking required environment variables..."
	@test -n "$(WALLET_PRIVATE_KEY)" || (echo "❌ WALLET_PRIVATE_KEY not set in .env" && exit 1)
	@test -n "$(EVM_RPC_URL)" || (echo "❌ EVM_RPC_URL not set in .env" && exit 1)
	@test -n "$(ETHERSCAN_API_KEY)" || (echo "❌ ETHERSCAN_API_KEY not set in .env" && exit 1)
	@echo "✅ Environment variables loaded from .env"
	forge script script/SetupDevChain.s.sol:SetupDevChain --rpc-url $(EVM_RPC_URL) --broadcast --verify

deploy-contract:
	@echo "Deploying CogniSignal contract with existing DAO"
	@echo "Checking required environment variables..."
	@test -n "$(WALLET_PRIVATE_KEY)" || (echo "❌ WALLET_PRIVATE_KEY not set in .env" && exit 1)
	@test -n "$(EVM_RPC_URL)" || (echo "❌ EVM_RPC_URL not set in .env" && exit 1)
	@test -n "$(DAO_ADDRESS)" || (echo "❌ DAO_ADDRESS not set in .env" && exit 1)
	@test -n "$(ETHERSCAN_API_KEY)" || (echo "❌ ETHERSCAN_API_KEY not set in .env" && exit 1)
	@echo "✅ Environment variables loaded from .env"
	forge script script/Deploy.s.sol:Deploy --rpc-url $(EVM_RPC_URL) --broadcast --verify