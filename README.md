# Juicebox Project Cards

Juicebox Project Cards are a fun way to keep track of the health of your favorite Juicebox projects, right inside your own wallet! Project Cards are ERC-1155 NFT editions. Each project card corresponds to a specific project on the Juicebox Protocol. Project Cards display the same metadata as the canonical Juicebox Project NFT. Project cards display up-to-date treasury statistics for the corresponding project. If project owners customize their project metadata, the project cards will automatically update accordingly.

## Live deployment
Mainnet: https://etherscan.io/address/0xe601eae33a0109147a6f3cd5f81997233d42fedd
OpenSea: https://opensea.io/collection/juicebox-project-cards

## Install
- Install Foundry and Yarn and get API keys for Etherscan and an [EVM RPC](https://ethereumnodes.com/)
- Update `.env.example` with your API keys and rename to `.env`
- Run `forge install && yarn`

## Test
- Fill out `.env.example` with your API keys and rename to `.env`. Only the Etherscan API key is required for testing.
- Run `forge test`

## Deploy
`forge script script/Goerli_Deploy.s.sol --rpc-url $GOERLI_RPC_URL --broadcast --verify` or the equivalent replacing both mentions of Goerli with Mainnet

## Credits
Thanks to DrGorilla, Jango, Based, Peri, and the support of JuiceboxDAO.