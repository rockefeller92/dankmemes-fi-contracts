const hre = require("hardhat");
const fs = require("fs");

async function main() {
	console.log('creating wallet..');
	let w = hre.ethers.Wallet.createRandom();
	let password = fs.readFileSync('./dankmemes.fi.pw','utf-8');
	let s = await w.encrypt(password);
	console.log(s);
	fs.writeFileSync('dankmemes.fi.json',s,'utf-8');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
	console.error(error);
	process.exit(1);
  });
