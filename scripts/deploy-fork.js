const hre = require("hardhat");

async function main() {
	console.log('compiling contracts..');
	await hre.run('compile');

	//deploy the buyTsla contract
	console.log('deploying contracts..');
	const BUYsTSLAFactory = await hre.ethers.getContractFactory("BUYsTSLA");
	const buySTSLA = await BUYsTSLAFactory.deploy();
	console.log("buySTSLA deployed to:", buySTSLA.address);
	await buySTSLA.deployed();

	//deploy the helper
	const HelperFactory = await hre.ethers.getContractFactory("Helper");
	const helper = await HelperFactory.deploy();
	console.log("Helper deployed to:", helper.address);
	await helper.deployed();

	//give the contract some ether
	const [sender] = await ethers.getSigners();

	console.log('sending helper contract some eth');
	const tx2 = await sender.sendTransaction({
		to: helper.address,
		value: ethers.constants.WeiPerEther
	});
	await tx2.wait();

	console.log("using helper contract's eth to buy USDC for the dev Metamask wallet");
	await helper.BuyUSDCForDevWallet();

	console.log("sending Brave Metamask dev wallet some ETH for gas");
	const tx3 = await sender.sendTransaction({
		to: "0xf69B8785468D0943eDBC4B090C6b356C3d0F20D0",
		value: ethers.constants.WeiPerEther
	});
	await tx3.wait();

	console.log("sending Chrome Metamask dev wallet some ETH for gas");
	const tx4 = await sender.sendTransaction({
		to: "0x55bb6f9D32AdD8150f8DC7B6CACeCaBf3B96A911",
		value: ethers.constants.WeiPerEther
	});
	await tx4.wait();

	//impersonate the synthetix account that can enable sTSLA trading
	await hre.network.provider.request({
		method: "hardhat_impersonateAccount",
		params: ["0xc105ea57eb434fbe44690d7dec2702e4a2fbfcf7"] //this is the account authorized to suspend/unsuspend a synth market
	});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
.then(() => process.exit(0))
.catch(error => {
console.error(error);
process.exit(1);
});
