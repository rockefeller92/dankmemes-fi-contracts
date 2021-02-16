//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract Helper {

	//these are used to seed developer wallet in build
	IUniswapV2Router02 usi = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	uint256 constant weiParEther = 1000000000000000000;
	address constant MetamaskDevWallet = 0xf69B8785468D0943eDBC4B090C6b356C3d0F20D0;

	address constant USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	constructor() {
	}

  	receive() external payable {
		console.log('receiving ether: ');
		console.log(msg.value);
	}

	function BuyUSDCForDevWallet() public payable
	{
		console.log('buying usdc for dev wallet');
		uint256 etherAmountToSpend = weiParEther;
		uint deadline = block.timestamp + 300; // using 'now' for convenience, for mainnet pass deadline from frontend!
	
		uint[] memory amounts = usi.swapExactETHForTokens{value:etherAmountToSpend}(0, getPathForETHToToken(USDCAddress), MetamaskDevWallet, deadline);
		uint256 outputTokenCount = uint256(amounts[1]);
		console.log('USDC deposited to Metamask dev wallet:');
		console.log(outputTokenCount);
	}

	function getPathForETHToToken(address crypto) private view returns (address[] memory)
	{
		address[] memory path = new address[](2);
		path[0] = usi.WETH();
		path[1] = crypto;
	
		return path;
	}
}
