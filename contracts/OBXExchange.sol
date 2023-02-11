// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";
import {LinkedListLib} from "./LinkedList.sol";
import {OPVSetLib} from "./OPVSet.sol";
import {PVNodeLib} from "./PVNode.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IOBXReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 totalAmount, uint256 commission, address token) external;

    /**
    * @dev Returns referral count
    */
    function getReferralCount(address _referrer) external view returns (uint256);

    /**
    * @dev Returns referral rate
    */
    function getComissionRate(address _referrer) external view returns (uint256);
    
    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

contract OBXExchange is Ownable,ReentrancyGuard {
    
    address public factory;
    address public tokenA;
    address public tokenB;
    address public USDCToken = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public USDTToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public BRZToken = 0x491a4eB4f1FC3BfF8E1d2FC856a6A46663aD556f;
    address public KRSTMToken = 0x671078C0496Fa135a8c45fC7c9FA7B1501fD5146;
    address public WBTCToken = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public deployer = 0x55ADe9E7143bc597261e8D068c08817A932955df;
    // change after deployment of this contracts to correct addresses
    address public synteticPool = 0xab46459EeF8E197dC4A632D707Ee28C68A119400;
    address public stakingPool = 0x8A284F79589650Ad9f21CE9F6E6d50d7B3b9805b;
    address public lotteryPool = 0xB809E5E801372Ce25fa059e598304E423f581486;
    address public obxReferralAddress;

    uint16 public feeRate;
    uint256 public tokenAaccumulatedFee;
    uint256 public tokenBaccumulatedFee;

    uint256 currentFee; 
    uint256 amountInQuote;
    uint256 amountGiven;
    uint256 amountReceive;
    uint256 minAmount;

    // OBX referral contract address.
    IOBXReferral public obxReferral;

    IUniswapV2Router02 public uniswapRouter;

    constructor(address _tokenA, address _tokenB, address _obxReferral) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        factory = msg.sender;
        obxReferral = IOBXReferral(_obxReferral);
        obxReferralAddress = _obxReferral;
        _transferOwnership(deployer);
        
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        
        uniswapRouter = _uniswapRouter;

    }

    // addr A deposit B token, C many
    mapping(address => mapping(address => uint256)) deposits;

    // token A, price B, orders[seller, amount]
    mapping(address => mapping(uint256 => LinkedListLib.LinkedList))
        public orderBook;

    // addr A: [[sellOrderId, price, volume]]
    OPVSetLib.OPVset private _sellOrders;
    OPVSetLib.OPVset private _buyOrders;

    // [[price, volume]]
    PVNodeLib.PVnode[] private sellOB;
    PVNodeLib.PVnode[] private buyOB;
    
    //A way to store filled orders

    event Trade(uint otype, uint64 indexed price, uint256 amountGet, uint256 amountGive, address indexed userFill, address indexed userFilled, uint256 timestamp);
  
    function distributeFees() public {
        if(tokenA == KRSTMToken){

            IERC20(tokenA).transfer(deployer, tokenAaccumulatedFee/3);
            IERC20(tokenA).transfer(synteticPool, tokenAaccumulatedFee/3);
            IERC20(tokenA).transfer(lotteryPool, tokenAaccumulatedFee/3);

        } else if (tokenA == USDCToken || tokenA == USDTToken){

            IERC20(tokenA).transfer(deployer, tokenAaccumulatedFee / 10**12);

        } else if(tokenA == WBTCToken){

            IERC20(tokenA).transfer(deployer, tokenAaccumulatedFee / 10**10);

        } else {

            IERC20(tokenA).transfer(deployer, tokenAaccumulatedFee);

        }

        if(tokenB == USDCToken){

            IERC20(tokenB).transfer(deployer, (tokenBaccumulatedFee/2) / 10**12);
            IERC20(tokenB).transfer(stakingPool, (tokenBaccumulatedFee/2) / 10**12);

        } else if (tokenB == BRZToken){

            IERC20(tokenB).transfer(deployer, tokenBaccumulatedFee / 10**14);

        } else{ 

            IERC20(tokenB).transfer(deployer, tokenBaccumulatedFee);

        }

        tokenAaccumulatedFee = 0;
        tokenBaccumulatedFee = 0;
    }

    //In case of new router version
    function changeRouter(address _routerAddress) public onlyOwner() {
        
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(_routerAddress);
        
        uniswapRouter = _uniswapRouter;

    }

    function deposit(address tokenAddress, uint256 amount)
        private
        returns (bool)
    {
        require(
            tokenAddress == tokenA || tokenAddress == tokenB,
            "Deposited token is not in the pool"
        );
        deposits[msg.sender][tokenAddress] += amount;
        
        if(tokenAddress == USDCToken || tokenAddress == USDTToken){
            amount = amount / 10**12;
        } else if (tokenAddress == BRZToken){
            amount = amount / 10**14;
        } else if (tokenAddress == WBTCToken){
            amount = amount / 10**10;
        }

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        
        return true;
    }

    function withdraw(address tokenAddress, uint256 amount)
        private
        returns (bool)
    {
        require(
            tokenAddress == tokenA || tokenAddress == tokenB,
            "Withdrawn token is not in the pool"
        );
        require(
            deposits[msg.sender][tokenAddress] >= amount,
            "Withdraw amount exceeds deposited"
        );
        deposits[msg.sender][tokenAddress] -= amount;
        if(tokenAddress == USDCToken || tokenAddress == USDTToken){
            amount = amount / 10**12;
        } else if (tokenAddress == BRZToken){
            amount = amount / 10**14;
        } else if (tokenAddress == WBTCToken){
            amount = amount / 10**10;
        }
        IERC20(tokenAddress).transfer(msg.sender, amount);
        return true;
    }
    
    function setEcosystemWallets(address _synteticContract, address _stakingContract, address _lotteryContract ) public onlyOwner {
        synteticPool = _synteticContract;
        stakingPool = _stakingContract;
        lotteryPool = _lotteryContract;
    }

    function setFeeReceiver(address _deployer) public onlyOwner {
        deployer = _deployer;
    }

    function swapTokensToKRSTM(address token,uint256 tokenAmount) private {
        // generate the swap pair path of tokens
        address[] memory path;

        if(token == BRZToken){
            path = new address[](4);
            path[0] = token;
            path[1] = USDCToken;
            path[2] = uniswapRouter.WETH();
            path[3] = KRSTMToken;

            tokenAmount = tokenAmount / 10**14;

        } else if(token == 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd){
            path = new address[](2);
            path[0] = token;
            path[1] = KRSTMToken;
       } else{
            path = new address[](3);
            path[0] = token;
            path[1] = uniswapRouter.WETH();
            path[2] = KRSTMToken;

            if(token == USDCToken || token == USDTToken){
                tokenAmount = tokenAmount / 10**12;
            } else if(token == WBTCToken){
                tokenAmount = tokenAmount / 10**10;
            }
       }

        IERC20(token).approve(address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of Tokens out
            path,
            obxReferralAddress, // The contract
            block.timestamp + 300
        );
    }

    function getDeposits(address account, address tokenAddress)
        external
        view
        returns (uint256)
    {
        require(
            tokenAddress == tokenA || tokenAddress == tokenB,
            "Token is not in the pool"
        );
        return deposits[account][tokenAddress];
    }
   
    function refBuy(address _referrer,uint256 _amount,uint256 _fee,address _token,bool _type) internal {
        
        uint256 referralCommissionRate = obxReferral.getComissionRate(_referrer);

        uint256 referralAmount = _fee*referralCommissionRate/10000;

        obxReferral.recordReferralCommission(_referrer,_amount,referralAmount,_token);

        if(_type == false){
        
        tokenAaccumulatedFee += _fee - referralAmount;
        
        } else{
        
        tokenBaccumulatedFee += _fee - referralAmount;
        
        }
        swapTokensToKRSTM(_token,referralAmount);

    }

    function getFeeRate(address _user) internal {
        if(IERC20(KRSTMToken).balanceOf(_user) >= 6.75 * 10 **18){
           feeRate = 75;
        } else if(IERC20(KRSTMToken).balanceOf(_user) >= 2.25 * 10 **18){
           feeRate = 250;
        } else if(IERC20(KRSTMToken).balanceOf(_user) >= 0.75 * 10 **18){
           feeRate = 500;
        } else if(IERC20(KRSTMToken).balanceOf(_user) >= 0.25 * 10 **18){
           feeRate = 750;
        } else{
           feeRate = 1000;
        }

    }

    // Sell
    function newSellOrder(
        uint64 price,
        uint256 sellAmount,
        uint256 priceIdx,
        address _referrer
    ) external nonReentrant returns (bool) {
        // get priceIdx using the FE
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

        deposit(tokenA, sellAmount);
        
        //Record Referral
        address referrer = obxReferral.getReferrer(msg.sender);
        if (_referrer != address(0) && _referrer != msg.sender && referrer == address(0) && sellAmount > 0) {
            obxReferral.recordReferral(msg.sender, _referrer);
        }
    
        getFeeRate(msg.sender);

        currentFee = sellAmount * feeRate / 1000000;

        uint256 len = orderBook[tokenB][price].length;
        for (uint8 i = 0; i < len; i++) {
            bytes32 head_ = orderBook[tokenB][price].head;
            uint256 buyAmount = orderBook[tokenB][price]
                .nodes[head_]
                .order
                .amount;

            if (sellAmount == 0) {
                return true;
            } else if ((price * (sellAmount - currentFee)) / 1000 >= buyAmount) {                  

                // sell amount >= buy amount
                LinkedListLib.Order memory o = orderBook[tokenB][price]
                    .nodes[head_]
                    .order;
                LinkedListLib.popHead(orderBook[tokenB][price]);
                OPVSetLib._remove(_buyOrders, o.seller, head_);
                PVNodeLib._subVolume(buyOB, priceIdx, o.amount);

                amountGiven = (o.amount / price) * 1000;
                deposits[o.seller][tokenB] -= o.amount;

                deposits[msg.sender][tokenA] -= amountGiven;

                //Take Fee only from amount traded
                currentFee = amountGiven * feeRate / 1000000;
               
                if(tokenA == USDCToken || tokenA == USDTToken){
                    minAmount = 0.00001 *10**18;
                } else if (tokenA == WBTCToken){
                    minAmount = 0.0000001 *10**18;
                } else{
                    minAmount = 0.00001 *10**18;
                }

                if(referrer != address(0) && obxReferral.getReferralCount(referrer) >= 5 && currentFee > minAmount){

                    refBuy(referrer,amountGiven,currentFee,tokenA,false);

                } else{
                    tokenAaccumulatedFee += currentFee;
                }

                deposits[msg.sender][tokenA] -= currentFee;
                sellAmount -= currentFee;

                if(tokenB == USDCToken){
                  IERC20(tokenB).transfer(msg.sender, o.amount / 10**12);
                } else if (tokenB == BRZToken){
                  IERC20(tokenB).transfer(msg.sender, o.amount / 10**14);
                }

                if(tokenA == USDTToken || tokenA == USDCToken){
                IERC20(tokenA).transfer(o.seller, amountGiven / 10**12);
                } else if (tokenA == WBTCToken ){
                IERC20(tokenA).transfer(o.seller, amountGiven / 10**10);   
                } else{
                IERC20(tokenA).transfer(o.seller, amountGiven);
                }
               
                emit Trade(0, price, o.amount, amountGiven, msg.sender, o.seller, block.timestamp);

                sellAmount -= amountGiven;

            } else if (buyAmount > (price * (sellAmount - currentFee)) / 1000) {
       
                if(tokenA == USDCToken || tokenA == USDTToken){
                    minAmount = 0.00001 *10**18;
                } else if (tokenA == WBTCToken){
                    minAmount = 0.0000001 *10**18;
                } else{
                    minAmount = 0.00001 *10**18;
                }

                if(referrer != address(0) && obxReferral.getReferralCount(referrer) >= 5 && currentFee > minAmount){
                        
                        refBuy(referrer,sellAmount,currentFee,tokenA,false);

                    } else{
                       
                        tokenAaccumulatedFee += currentFee;
                    }

                deposits[msg.sender][tokenA] -= currentFee;
                sellAmount -= currentFee;

                amountReceive = (price * sellAmount) / 1000;

                LinkedListLib.Order memory o = orderBook[tokenB][price]
                    .nodes[head_]
                    .order;
                orderBook[tokenB][price].nodes[head_].order.amount -=
                    amountReceive;
                OPVSetLib._subVolume(
                    _buyOrders,
                    o.seller,
                    head_,
                    amountReceive
                );
                PVNodeLib._subVolume(buyOB, priceIdx, amountReceive);

                deposits[o.seller][tokenB] -= amountReceive;
                deposits[msg.sender][tokenA] -= sellAmount;

                
                if(tokenB == USDCToken){
                  IERC20(tokenB).transfer(msg.sender, amountReceive / 10**12);
                } else if (tokenB == BRZToken){
                  IERC20(tokenB).transfer(msg.sender, amountReceive / 10**14);
                }

                if(tokenA == USDTToken || tokenA == USDCToken){
                IERC20(tokenA).transfer(o.seller, sellAmount / 10**12);
                } else if (tokenA == WBTCToken ){
                IERC20(tokenA).transfer(o.seller, sellAmount / 10**10);   
                } else{
                IERC20(tokenA).transfer(o.seller, sellAmount);
                }
                
                emit Trade(0, price, amountReceive , sellAmount, msg.sender, o.seller, block.timestamp);

                sellAmount = 0;
            }
        }
        // new sell order
        if (orderBook[tokenA][price].length == 0 && sellAmount > 0) {
            bytes32 orderId = LinkedListLib.initHead(
                orderBook[tokenA][price],
                msg.sender,
                sellAmount
            );
            OPVSetLib._add(_sellOrders, msg.sender, orderId, price, sellAmount);
            PVNodeLib._addVolume(sellOB, priceIdx, sellAmount);
        } else if (sellAmount > 0) {
            bytes32 orderId = LinkedListLib.addNode(
                orderBook[tokenA][price],
                msg.sender,
                sellAmount
            );
            OPVSetLib._add(_sellOrders, msg.sender, orderId, price, sellAmount);
            PVNodeLib._addVolume(sellOB, priceIdx, sellAmount);
        }

        if(tokenBaccumulatedFee >= 50 * 10 ** 18 ){
            distributeFees();
        }

        return true;
    }

    function getAllSellOrders(uint64 price)
        external
        view
        returns (LinkedListLib.Order[] memory)
    {
        LinkedListLib.Order[] memory orders = new LinkedListLib.Order[](
            orderBook[tokenA][price].length
        );

        bytes32 currId = orderBook[tokenA][price].head;

        for (uint256 i = 0; i < orderBook[tokenA][price].length; i++) {
            orders[i] = orderBook[tokenA][price].nodes[currId].order;
            currId = orderBook[tokenA][price].nodes[currId].next;
        }
        return orders;
    }

    function activeSellOrders()
        external
        view
        returns (OPVSetLib.OPVnode[] memory)
    {
        OPVSetLib.OPVnode[] memory sellOrders = new OPVSetLib.OPVnode[](
            _sellOrders._orders[msg.sender].length
        );

        for (uint256 i = 0; i < _sellOrders._orders[msg.sender].length; i++) {
            sellOrders[i] = _sellOrders._orders[msg.sender][i];
        }
        return sellOrders;
    }

    function deleteSellOrder(
        uint64 price,
        bytes32 orderId,
        uint256 priceIdx
    ) external returns (bool) {
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

        LinkedListLib.Order memory o = orderBook[tokenA][price]
            .nodes[orderId]
            .order;
        require(msg.sender == o.seller, "Seller does not match the caller");

        withdraw(tokenA, o.amount);

        LinkedListLib.deleteNode(orderBook[tokenA][price], orderId);
        OPVSetLib._remove(_sellOrders, msg.sender, orderId);
        PVNodeLib._subVolume(sellOB, priceIdx, o.amount);

        return true;
    }

    // Buy
    function newBuyOrder(
        uint64 price,
        uint256 buyAmount,
        uint256 priceIdx,
        address _referrer
    ) external nonReentrant returns (bool) {
        // get priceIdx using the FE
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

        deposit(tokenB, (price * buyAmount) / 1000);
        
        //Record Referral
        address referrer = obxReferral.getReferrer(msg.sender);
        if (_referrer != address(0) && _referrer != msg.sender && referrer == address(0) && buyAmount > 0) {
            obxReferral.recordReferral(msg.sender, _referrer);
        }


        getFeeRate(msg.sender);

        amountInQuote = (price * buyAmount) / 1000;
        currentFee = amountInQuote * feeRate / 1000000;

        uint256 len = orderBook[tokenA][price].length;
        for (uint8 i = 0; i < len; i++) {
            bytes32 head_ = orderBook[tokenA][price].head;
            uint256 sellAmount = orderBook[tokenA][price]
                .nodes[head_]
                .order
                .amount;

            if (buyAmount == 0) {
                return true;
            } else if (((amountInQuote - currentFee) / price) * 1000 >= sellAmount) {
                
                // buy amount >= sell amount
                LinkedListLib.Order memory o = orderBook[tokenA][price]
                    .nodes[head_]
                    .order;
                LinkedListLib.popHead(orderBook[tokenA][price]);
                OPVSetLib._remove(_sellOrders, o.seller, head_);
                PVNodeLib._subVolume(sellOB, priceIdx, o.amount);
                
                amountGiven = (price * o.amount) / 1000;

                deposits[o.seller][tokenA] -= o.amount;
                deposits[msg.sender][tokenB] -= amountGiven;

                //Take Fee only from amount traded
                currentFee = amountGiven * feeRate / 1000000;

                if(tokenB == BRZToken){
                    minAmount = 0.001 *10**18;
                }else{
                    minAmount = 0.00001 *10**18;
                }

                if(referrer != address(0) && obxReferral.getReferralCount(referrer) >= 5 && currentFee > minAmount){
                    
                    refBuy(referrer,amountGiven,currentFee,tokenB,true);

                } else{

                    tokenBaccumulatedFee += currentFee;

                }

                deposits[msg.sender][tokenB] -= currentFee;
                buyAmount = ((amountInQuote - currentFee) / price) * 1000;
                
                if(tokenA == USDTToken || tokenA == USDCToken){
                 IERC20(tokenA).transfer(msg.sender, o.amount / 10**12);
                } else if (tokenA == WBTCToken ){
                 IERC20(tokenA).transfer(msg.sender, o.amount / 10**10);   
                } else{
                 IERC20(tokenA).transfer(msg.sender, o.amount);
                }

                if(tokenB == USDCToken){
                  IERC20(tokenB).transfer(o.seller, amountGiven / 10**12);
                } else if (tokenB == BRZToken){
                  IERC20(tokenB).transfer(o.seller, amountGiven / 10**14);
                } else{
                  IERC20(tokenB).transfer(o.seller, amountGiven); 
                }

                emit Trade(1, price, o.amount, amountGiven, msg.sender, o.seller, block.timestamp);

                 buyAmount -= o.amount;
                
            } else if (sellAmount > ((amountInQuote - currentFee) / price) * 1000) {
                    

                if(tokenB == BRZToken){
                    minAmount = 0.001 *10**18;
                }else{
                    minAmount = 0.00001 *10**18;
                }

                if(referrer != address(0) && obxReferral.getReferralCount(referrer) >= 5 && currentFee > minAmount){
                        
                        refBuy(referrer,amountInQuote,currentFee,tokenB,true);

                    } else{

                        tokenBaccumulatedFee += currentFee;

                    }

                    deposits[msg.sender][tokenB] -= currentFee;
                    buyAmount = ((amountInQuote - currentFee) / price) * 1000;
                

                amountGiven = (price * buyAmount) / 1000;

                LinkedListLib.Order memory o = orderBook[tokenA][price]
                    .nodes[head_]
                    .order;
                orderBook[tokenA][price].nodes[head_].order.amount -= buyAmount;
                OPVSetLib._subVolume(_sellOrders, o.seller, head_, buyAmount);
                PVNodeLib._subVolume(sellOB, priceIdx, buyAmount);

                deposits[o.seller][tokenA] -= buyAmount;
                deposits[msg.sender][tokenB] -= amountGiven;

                if(tokenA == USDTToken || tokenA == USDCToken){
                 IERC20(tokenA).transfer(msg.sender, buyAmount / 10**12);
                } else if (tokenA == WBTCToken ){
                 IERC20(tokenA).transfer(msg.sender, buyAmount / 10**10);   
                } else{
                 IERC20(tokenA).transfer(msg.sender, buyAmount);
                }

                if(tokenB == USDCToken){
                  IERC20(tokenB).transfer(o.seller, amountGiven / 10**12);
                } else if (tokenB == BRZToken){
                  IERC20(tokenB).transfer(o.seller, amountGiven / 10**14);
                } else{
                  IERC20(tokenB).transfer(o.seller, amountGiven);
                }
                
                emit Trade(1, price, buyAmount, amountGiven , msg.sender, o.seller, block.timestamp);

                buyAmount = 0;
            }
        }
        // new buy order
        if (orderBook[tokenB][price].length == 0 && buyAmount > 0) {
            bytes32 orderId = LinkedListLib.initHead(
                orderBook[tokenB][price],
                msg.sender,
                (price * buyAmount) / 1000
            );
            OPVSetLib._add(
                _buyOrders,
                msg.sender,
                orderId,
                price,
                (price * buyAmount) / 1000
            );
            PVNodeLib._addVolume(buyOB, priceIdx, (price * buyAmount) / 1000);
        } else if (buyAmount > 0) {
            bytes32 orderId = LinkedListLib.addNode(
                orderBook[tokenB][price],
                msg.sender,
                (price * buyAmount) / 1000
            );
            OPVSetLib._add(
                _buyOrders,
                msg.sender,
                orderId,
                price,
                (price * buyAmount) / 1000
            );
            PVNodeLib._addVolume(buyOB, priceIdx, (price * buyAmount) / 1000);
        }

        if(tokenBaccumulatedFee >= 50 * 10 ** 18 ){
            distributeFees();
        }
        

        return true;
    }

    function deleteBuyOrder(
        uint64 price,
        bytes32 orderId,
        uint256 priceIdx
    ) external returns (bool) {
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

        LinkedListLib.Order memory o = orderBook[tokenB][price]
            .nodes[orderId]
            .order;
        require(msg.sender == o.seller, "Seller does not match the caller");

        withdraw(tokenB, o.amount);

        LinkedListLib.deleteNode(orderBook[tokenB][price], orderId);
        OPVSetLib._remove(_buyOrders, msg.sender, orderId);
        PVNodeLib._subVolume(buyOB, priceIdx, o.amount);

        return true;
    }

    function getAllBuyOrders(uint64 price)
        external
        view
        returns (LinkedListLib.Order[] memory)
    {
        LinkedListLib.Order[] memory orders = new LinkedListLib.Order[](
            orderBook[tokenB][price].length
        );

        bytes32 currId = orderBook[tokenB][price].head;

        for (uint256 i = 0; i < orderBook[tokenB][price].length; i++) {
            orders[i] = orderBook[tokenB][price].nodes[currId].order;
            currId = orderBook[tokenB][price].nodes[currId].next;
        }
        return orders;
    }

    function activeBuyOrders()
        external
        view
        returns (OPVSetLib.OPVnode[] memory)
    {
        OPVSetLib.OPVnode[] memory buyOrders = new OPVSetLib.OPVnode[](
            _buyOrders._orders[msg.sender].length
        );

        for (uint256 i = 0; i < _buyOrders._orders[msg.sender].length; i++) {
            buyOrders[i] = _buyOrders._orders[msg.sender][i];
        }
        return buyOrders;
    }

    // sellOB + buyOB functions
    function getPVobs()
        external
        view
        returns (PVNodeLib.PVnode[] memory, PVNodeLib.PVnode[] memory)
    {
        return (sellOB, buyOB);
    }

    function initPVnode(uint64 price) external returns (uint256) {
        if (
            orderBook[tokenA][price].tail == "" &&
            orderBook[tokenB][price].tail == ""
        ) {
            orderBook[tokenA][price].tail = "1"; // placeholder
            sellOB.push(PVNodeLib.PVnode(price, 0));
            buyOB.push(PVNodeLib.PVnode(price, 0));
            return buyOB.length - 1;
        }
        revert("Price already exist");
    }

    function getIndexOfPrice(uint64 price) external view returns (uint256) {
        for (uint256 i = 0; i < sellOB.length; i++) {
            if (sellOB[i].price == price) {
                return i;
            }
        }
        revert("Price is not in the array");
    }
}