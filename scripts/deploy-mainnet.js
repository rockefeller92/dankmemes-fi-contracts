const hre = require("hardhat");
const fs = require("fs");

async function main() {
	console.log('loading wallet..');
	let password = fs.readFileSync('./dankmemes.fi.pw','utf-8');
	const w = await hre.ethers.Wallet.fromEncryptedJson(fs.readFileSync('./dankmemes.fi.json','utf-8'), password);
	const deployer = w.connect(hre.ethers.provider);

	console.log(
		"Deploying contracts with the account:",
		deployer.address
	);

	console.log("Account balance:", (await deployer.getBalance()).toString());
	console.log("getting factory..");
	const _factory = await ethers.getContractFactory("BUYsTSLA");
	const factory = _factory.connect(deployer);

	console.log("deploying..");
	const contract = await factory.deploy({gasLimit:12487794});
	
	console.log("Contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
