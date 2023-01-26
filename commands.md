forge script script/timsg.s.sol:TimsgScript --fork-url $INFURA_GOERLI_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_TOKEN --verify --broadcast

forge script script/nftmsg.s.sol:NftmsgScript --fork-url $INFURA_GOERLI_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_TOKEN --verify --broadcast

cast send --rpc-url $INFURA_GOERLI_URL --private-key $PRIVATE_KEY 0x5e56efe119f4aa3bf9c26856063c21a83b26d529 "mintToTest()"

MAINNET

forge script script/timsg.s.sol:TimsgScript --fork-url $INFURA_MAINNET_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_TOKEN --verify --broadcast