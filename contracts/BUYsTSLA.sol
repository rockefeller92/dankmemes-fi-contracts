//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ICurveSUSD.sol";
import "../interfaces/ISynthetix.sol";
import "../interfaces/IExchanger.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IBalancerPool.sol";

contract BUYsTSLA
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	//consts for USDC to sUSD on curve.fi
	IERC20 sUSD = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
	IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	IERC20 sTSLA = IERC20(0x918dA91Ccbc32B7a6A0cc4eCd5987bbab6E31e6D);

	address constant CurveSUSDSwapAddress = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
	ICurveSUSD crvSUSDSwap = ICurveSUSD(CurveSUSDSwapAddress);

	int128 constant USDCIndex = 1;
	int128 constant sUSDIndex = 3;


	//consts for sUSD to sTSLA on Synthetix
	address constant SynthetixAddress    = 0x97767D7D04Fd0dB0A1a2478DCd4BA85290556B48;

	ISynthetix Synthetix                = ISynthetix(SynthetixAddress);
	IExchanger SynthetixExchanger       = IExchanger(0x0bfDc04B38251394542586969E2356d0D731f7DE);
	ISystemStatus SynthetixSystemStatus = ISystemStatus(0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E);

	bytes32 sUSDKey  = 0x7355534400000000000000000000000000000000000000000000000000000000;
	bytes32 sTSLAKey = 0x7354534c41000000000000000000000000000000000000000000000000000000;

	//for sUSD to sTSLA on Balancer
	address constant BalancerAddress = 0x055dB9AFF4311788264798356bbF3a733AE181c6;
	IBalancerPool  BalancerPool = IBalancerPool(BalancerAddress);

	constructor() {}

	//estimate how much sUSD you can get for USDC
	function est_swap_usdc_to_susd(uint256 usdc_amount) public view returns (uint256 )
	{
		uint256 susd_amount = crvSUSDSwap.get_dy(USDCIndex, sUSDIndex, usdc_amount);
		return susd_amount;
	}

	function stsla_suspended() public view returns (bool ) {
		(bool suspended, ) = SynthetixSystemStatus.synthExchangeSuspension(sTSLAKey);
		return suspended;
	}

	//estimate how much sTSLA you can get for USDC (will use Synthetix or Balancer depending on use_synthetix)
	function est_swap_usdc_to_stsla(uint256 usdc_amount, bool use_synthetix) public view returns (uint256 )
	{
		uint256 expectedSUSD = est_swap_usdc_to_susd(usdc_amount);

		if (use_synthetix)
		{
			(uint amount_expected,
			/*uint fee*/,
			/*uint exchangeFeeRate*/) = SynthetixExchanger.getAmountsForExchange(expectedSUSD, sUSDKey, sTSLAKey);
		
			return amount_expected;
		}
		else
		{
			//if not synthetix, use balancer
			uint256 sUSDAmount = BalancerPool.getBalance(address(sUSD));
			uint256 sTSLAAmount = BalancerPool.getBalance(address(sTSLA));
			uint256 sUSDWeight = BalancerPool.getDenormalizedWeight(address(sUSD));
			uint256 sTSLAWeight = BalancerPool.getDenormalizedWeight(address(sTSLA));
			uint256 fee = BalancerPool.getSwapFee();

			uint256 amount_expected = BalancerPool.calcOutGivenIn(sUSDAmount, sUSDWeight, sTSLAAmount, sTSLAWeight, expectedSUSD, fee);

			return amount_expected;
		}

	}

	//make the USDC -> sTSLA swap
	//goes through curve and then through Synthetix or Balancer depending on use_synthetix
	function swap_usdc_to_stsla(uint256 usdc_amount, bool use_synthetix) payable external returns (uint256 )
	{
		//transfer incoming USDC funds from caller to this contract
		USDC.safeTransferFrom(msg.sender, address(this), usdc_amount);

		//approve sending of USDC from this contract to Curve
		USDC.safeApprove(CurveSUSDSwapAddress, usdc_amount);
		
		//estimate how much susd we should expect back
		uint256 susd_expected = est_swap_usdc_to_susd(usdc_amount);

		//establish minimum expected at 1% less than expected amount
		uint256 min_susd_expected = susd_expected.sub(susd_expected.div(100));

		//TODO: this above expected amount should actually come from a value displayed to the user
		//prior to approving the transaction
		//there can't be any "slippage" between the above estimate and the swap below
		//since this is all in the same atomic transaction

		//note the current balance of sUSD before and after exchange on curve, this
		//is the only definitive way to know how much we received
		uint256 before_susd_balance = sUSD.balanceOf(address(this));

		//swap USDC for sUSD on curve
		crvSUSDSwap.exchange(USDCIndex,sUSDIndex,usdc_amount,min_susd_expected);

		//determine how much sUSD received in the swap
		uint256 after_susd_balance = sUSD.balanceOf(address(this));
		uint256 susd_received = after_susd_balance.sub(before_susd_balance);

		//now turn sUSD it into sTSLA 

		if (use_synthetix)
		{
			//finish sUSD->sTSLA on Synthetix

			//first we give the SUSD back to the caller
			sUSD.safeTransfer(msg.sender, susd_received);

			//then ask Synthetix to perform the exchange on behalf of the caller
			//(the exchange will use the callers sUSD which we just returned to them,
			//make the trade, and then deposit the sTSLA with the caller)
			//
			//NOTE this requires that the caller has already given permission (in a separate eth transaction)
			//to our contract to trade on their behalf
			//that is done via Synthetix IDelegateApprovals.approveExchangeOnBehalf

			uint stsla_received = Synthetix.exchangeOnBehalf(msg.sender, sUSDKey, susd_received, sTSLAKey);

			return stsla_received;
		}
		else
		{
			//finish sUSD->sTSLA on Balancer

			//give Balancer contract permission to take susd_received from us
			sUSD.safeApprove(BalancerAddress, susd_received);

			// Swap sUSD for sTSLA on Balancer
			// TODO we should specify the min amount of sTSLA received and max price in this call
			(uint stsla_received, ) = BalancerPool.swapExactAmountIn(address(sUSD), susd_received, address(sTSLA), 0, uint256(-1));

			//send sTSLA back to the caller
			sTSLA.safeTransfer(msg.sender, stsla_received);

			return stsla_received;
		}
		
	}
}
