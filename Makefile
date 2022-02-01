
build: clean
	forge build --optimize --optimize-runs 1000000
.PHONY: build

clean:
	forge clean
.PHONY: clean

deploy-ropsten:
	forge create --constructor-args $(USDC) \
	             --constructor-args $(WETH) \
	             --constructor-args $(TREASURY_TOKEN) \
	             --constructor-args $(ETH_ORACLE) \
	             --constructor-args 0x0 \
	             --constructor-args $(TREASURY_ADDRESS) \
	             --constructor-args '' \
				 --constructor-args $(TOKEN_PRICE) \
				 --constructor-args $(TOKEN_PRICE_DECIMALS) \
				 --constructor-args $(TOKEN_DISCOUNT_BASIS_POINTS) \
	             --rpc-url https://ropsten.infura.io/v3/ \
				 --chain ropsten -i PoisonPill
.PHONY: deploy-ropsten

test:
	forge test -vvv --optimize --optimize-runs 1000000
.PHONY: test
