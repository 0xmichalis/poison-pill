build:
	forge build
.PHONY: build

test:
	forge test -vvv
.PHONY: test

fmt:
	forge fmt
.PHONY: fmt

lint:
	forge fmt --check
	slither .
.PHONY: lint

clean:
	forge clean
.PHONY: clean

# Loads deployment parameters from the environment — see .env.example
deploy-sepolia:
	forge script script/Deploy.s.sol \
		--rpc-url $(NODE_API_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY)
.PHONY: deploy-sepolia
