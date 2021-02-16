# dankmemes-fi-contracts

**BEFORE YOU DO ANYTHING**
Make sure you create a Mainnet "Developer" or "Staging" feed on Alchemy and put the URL into alchemy.config.json

Otherwise you will get mysterious error messages when running the hardhat fork.

```npm start``` will start your local fork.

In Metamask, select the "Localhost 8545" network

You will need some USDC in whatever account you want to test with. (Don't worry it will not actually be spent, spending only occurs on your local fork.)

I have a helper contract that swaps ETH for USDC and deposits it into my test Metamask account, you can do that if you need to.
