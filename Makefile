.PHONY: deploy-arbitrum deploy-ethereum update-env wire-oapps

# Load environment variables from .env file
include .env
export $(shell sed 's/=.*//' .env)

deploy-arbitrum:
    @echo "Deploying MonStaking on Arbitrum..."
    forge script scripts/DeployMonStaking.s.sol --rpc-url $(ARBITRUM_RPC_URL) --private-key $(ARBITRUM_DEPLOYER_PK) --broadcast | tee arbitrum_deploy.log
    @grep "Deployed MonStaking at:" arbitrum_deploy.log | awk '{print $$NF}' > arbitrum_address.txt

deploy-ethereum:
    @echo "Deploying MonStaking on Ethereum..."
    forge script scripts/DeployMonStaking.s.sol --rpc-url $(ETHEREUM_RPC_URL) --private-key $(ETHEREUM_DEPLOYER_PK) --broadcast | tee ethereum_deploy.log
    @grep "Deployed MonStaking at:" ethereum_deploy.log | awk '{print $$NF}' > ethereum_address.txt

update-env:
    @echo "Updating .env file with deployed contract addresses..."
    @sed -i '' 's/^ARBITRUM_MONSTAKING_OAPP=.*/ARBITRUM_MONSTAKING_OAPP=$(shell cat arbitrum_address.txt)/' .env
    @sed -i '' 's/^ETHEREUM_MONSTAKING_OAPP=.*/ETHEREUM_MONSTAKING_OAPP=$(shell cat ethereum_address.txt)/' .env

wire-oapps:
    @echo "Wiring MonStaking OApps on Arbitrum..."
    forge script scripts/WiringOappsScript.s.sol --rpc-url $(ARBITRUM_RPC_URL) --private-key $(ARBITRUM_DELEGATED_PK) --broadcast
    @echo "Wiring MonStaking OApps on Ethereum..."
    forge script scripts/WiringOappsScript.s.sol --rpc-url $(ETHEREUM_RPC_URL) --private-key $(ETHEREUM_DELEGATED_PK) --broadcast

deploy: deploy-arbitrum deploy-ethereum update-env wire-oapps