// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address delegate, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}


library LinkedListLib {
    struct Order {
        address seller;
        uint256 amount;
    }

    struct Node {
        bytes32 next;
        Order order;
    }

    struct LinkedList {
        uint256 length;
        bytes32 head;
        bytes32 tail;
        mapping(bytes32 => LinkedListLib.Node) nodes;
    }

    function initHead(
        LinkedList storage self,
        address _seller,
        uint256 _amount
    ) public returns (bytes32) {
        Order memory o = Order(_seller, _amount);
        Node memory n = Node(0, o);

        bytes32 id = keccak256(
            abi.encodePacked(_seller, _amount, self.length, block.timestamp)
        );

        self.nodes[id] = n;
        self.head = id;
        self.tail = id;
        self.length = 1;

        return id;
    }

    function getNode(LinkedList storage self, bytes32 _id)
        public
        view
        returns (Node memory)
    {
        return self.nodes[_id];
        // Q: Why "getter func" instead of `public`?
        // A: https://ethereum.stackexchange.com/questions/67137/why-creating-a-private-variable-and-a-getter-instead-of-just-creating-a-public-v
    }

    function getLength(LinkedList storage self) public view returns (uint256) {
        return self.length;
    }

    function addNode(
        LinkedList storage self,
        address _seller,
        uint256 _amount
    ) public returns (bytes32) {
        Order memory o = Order(_seller, _amount);
        Node memory n = Node(0, o);

        bytes32 id = keccak256(
            abi.encodePacked(_seller, _amount, self.length, block.timestamp)
        );

        self.nodes[id] = n;
        self.nodes[self.tail].next = id;
        self.tail = id;
        self.length += 1;
        return id;
    }

    function popHead(LinkedList storage self) public returns (bool) {
        bytes32 currHead = self.head;

        self.head = self.nodes[currHead].next;

        // delete's don't work for mappings so have to be set to 0
        // deleting is not necessary but we get partial refund
        delete self.nodes[currHead];
        self.length -= 1;
        return true;
    }

    function deleteNode(LinkedList storage self, bytes32 _id)
        public
        returns (bool)
    {
        if (self.head == _id) {
            require(
                self.nodes[_id].order.seller == msg.sender,
                "Unauthorised to delete this order."
            );
            popHead(self);
            return true;
        }

        bytes32 curr = self.nodes[self.head].next;
        bytes32 prev = self.head;

        // skipping node at index=0 (cuz its the head)
        for (uint256 i = 1; i < self.length; i++) {
            if (curr == _id) {
                require(
                    self.nodes[_id].order.seller == msg.sender,
                    "Unauthorised to delete this order."
                );
                self.nodes[prev].next = self.nodes[curr].next;
                delete self.nodes[curr];
                self.length -= 1;
                return true;
            }
            prev = curr;
            curr = self.nodes[prev].next;
        }
        revert("Order ID not found.");
    }
}


library OPVSetLib {
    struct OPVnode {
        bytes32 _orderId;
        uint64 _price;
        uint256 _volume;
    }

    struct OPVset {
        mapping(address => OPVnode[]) _orders;
        mapping(bytes32 => uint256) _indexes;
    }

    function _contains(OPVset storage set, bytes32 orderId)
        internal
        view
        returns (bool)
    {
        // 0 is a sentinel value
        return set._indexes[orderId] != 0;
    }

    function _at(
        OPVset storage set,
        address userAddress,
        uint256 index
    ) internal view returns (OPVnode memory) {
        return set._orders[userAddress][index];
    }

    function _add(
        OPVset storage set,
        address userAddress,
        bytes32 orderId,
        uint64 price,
        uint256 volume
    ) internal returns (bool) {
        if (!_contains(set, orderId)) {
            set._orders[userAddress].push(OPVnode(orderId, price, volume));
            set._indexes[orderId] = set._orders[userAddress].length;
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            return true;
        } else {
            return false;
        }
    }

    function _remove(
        OPVset storage set,
        address userAddress,
        bytes32 orderId
    ) internal returns (bool) {
        uint256 orderIdIndex = set._indexes[orderId];

        if (orderIdIndex != 0) {
            uint256 toDeleteIndex = orderIdIndex - 1;
            uint256 lastIndex = set._orders[userAddress].length - 1;

            if (lastIndex != toDeleteIndex) {
                OPVnode memory lastOPVnode = set._orders[userAddress][
                    lastIndex
                ];

                // Move the last value to the index where the value to delete is
                set._orders[userAddress][toDeleteIndex] = lastOPVnode;
                // Update the index for the moved value
                set._indexes[lastOPVnode._orderId] = orderIdIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._orders[userAddress].pop();

            // Delete the index for the deleted slot
            delete set._indexes[orderId];

            return true;
        } else {
            return false;
        }
    }

    function _addVolume(
        OPVset storage set,
        address userAddress,
        bytes32 orderId,
        uint256 volume
    ) internal returns (bool) {
        uint256 orderIdIndex = set._indexes[orderId];

        if (orderIdIndex != 0) {
            set._orders[userAddress][orderIdIndex - 1]._volume += volume;
            return true;
        } else {
            return false;
        }
    }

    function _subVolume(
        OPVset storage set,
        address userAddress,
        bytes32 orderId,
        uint256 volume
    ) internal returns (bool) {
        uint256 orderIdIndex = set._indexes[orderId];

        if (orderIdIndex != 0) {
            set._orders[userAddress][orderIdIndex - 1]._volume -= volume;
            return true;
        } else {
            return false;
        }
    }
}

library PVNodeLib {
    // price-volume node
    struct PVnode {
        uint64 price;
        uint256 volume;
    }

    function _addVolume(
        PVnode[] storage ob,
        uint256 index,
        uint256 changeAmount
    ) internal returns (bool) {
        ob[index].volume += changeAmount;
        return true;
    }

    function _subVolume(
        PVnode[] storage ob,
        uint256 index,
        uint256 changeAmount
    ) internal returns (bool) {
        ob[index].volume -= changeAmount;
        return true;
    }
}

contract OBXExchange is Ownable {
    address public factory;
    address public tokenA;
    address public tokenB;
    uint16 public feeRate;
    uint256 public tokenAaccumulatedFee;
    uint256 public tokenBaccumulatedFee;

    constructor(address _tokenA, address _tokenB, address _deployer) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        factory = msg.sender;
        _transferOwnership(_deployer);
        feeRate = 999; // 0.1%
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

    function Fee500() public onlyOwner {
        feeRate = 500; //  0.05%  > in case platform grows or for specific pairs
    }

    function Fee200() public onlyOwner {
        feeRate = 200; //  0.02%  > in case platform grows or for specific pairs
    }

    function deposit(address tokenAddress, uint256 amount)
        private
        returns (bool)
    {
        require(
            tokenAddress == tokenA || tokenAddress == tokenB,
            "Deposited token is not in the pool"
        );
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender][tokenAddress] += amount;
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
        IERC20(tokenAddress).transfer(msg.sender, amount);
        deposits[msg.sender][tokenAddress] -= amount;
        return true;
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

    // Sell
    function newSellOrder(
        uint64 price,
        uint256 sellAmount,
        uint256 priceIdx
    ) external returns (bool) {
        // get priceIdx using the FE
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

        // no fee under 1000
        deposit(tokenA, sellAmount);
        uint256 currentFee = (sellAmount * (1000-feeRate)) / 1000;
        tokenAaccumulatedFee += currentFee;
        deposits[msg.sender][tokenA] -= currentFee;
        sellAmount -= currentFee;

        uint256 len = orderBook[tokenB][price].length;
        for (uint8 i = 0; i < len; i++) {
            bytes32 head_ = orderBook[tokenB][price].head;
            uint256 buyAmount = orderBook[tokenB][price]
                .nodes[head_]
                .order
                .amount;

            if (sellAmount == 0) {
                return true;
            } else if ((price * sellAmount) / 1000 >= buyAmount) {
                // sell amount >= buy amount
                LinkedListLib.Order memory o = orderBook[tokenB][price]
                    .nodes[head_]
                    .order;
                LinkedListLib.popHead(orderBook[tokenB][price]);
                OPVSetLib._remove(_buyOrders, o.seller, head_);
                PVNodeLib._subVolume(buyOB, priceIdx, o.amount);

                uint256 amountGiven = (o.amount / price) * 100;

                deposits[o.seller][tokenB] -= o.amount;
                deposits[msg.sender][tokenA] -= amountGiven;
                IERC20(tokenB).transfer(msg.sender, o.amount);
                IERC20(tokenA).transfer(o.seller, amountGiven);
                
                emit Trade(0, price, o.amount, amountGiven, msg.sender, o.seller, block.timestamp);

                sellAmount -= amountGiven;

            } else if (buyAmount > (price * sellAmount) / 1000) {
                
                uint256 amountReceive = (price * sellAmount) / 1000;

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
                IERC20(tokenB).transfer(msg.sender, amountReceive);
                IERC20(tokenA).transfer(o.seller, sellAmount);
                
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
        uint256 priceIdx
    ) external returns (bool) {
        // get priceIdx using the FE
        require(
            buyOB[priceIdx].price == price && sellOB[priceIdx].price == price,
            "Price does not match the index"
        );

		// no fee under 1000
        deposit(tokenB, (price * buyAmount) / 1000);
        uint256 currentFee = (price * (buyAmount * (1000-feeRate)) / 1000) / 1000;
        tokenBaccumulatedFee += currentFee;
        deposits[msg.sender][tokenB] -= currentFee;
        buyAmount -= (buyAmount * (1000-feeRate)) / 1000;

        uint256 len = orderBook[tokenA][price].length;
        for (uint8 i = 0; i < len; i++) {
            bytes32 head_ = orderBook[tokenA][price].head;
            uint256 sellAmount = orderBook[tokenA][price]
                .nodes[head_]
                .order
                .amount;

            if (buyAmount == 0) {
                return true;
            } else if (buyAmount >= sellAmount) {
                // buy amount >= sell amount
                LinkedListLib.Order memory o = orderBook[tokenA][price]
                    .nodes[head_]
                    .order;
                LinkedListLib.popHead(orderBook[tokenA][price]);
                OPVSetLib._remove(_sellOrders, o.seller, head_);
                PVNodeLib._subVolume(sellOB, priceIdx, o.amount);
                
                uint256 amountGiven = (price * o.amount) / 1000;

                deposits[o.seller][tokenA] -= o.amount;
                deposits[msg.sender][tokenB] -= amountGiven;
                IERC20(tokenA).transfer(msg.sender, o.amount);
                IERC20(tokenB).transfer(o.seller, amountGiven);

                emit Trade(1, price, o.amount, amountGiven, msg.sender, o.seller, block.timestamp);

                buyAmount -= o.amount;
            } else if (sellAmount > buyAmount) {
                uint256 amountGiven = (price * buyAmount) / 1000;

                LinkedListLib.Order memory o = orderBook[tokenA][price]
                    .nodes[head_]
                    .order;
                orderBook[tokenA][price].nodes[head_].order.amount -= buyAmount;
                OPVSetLib._subVolume(_sellOrders, o.seller, head_, buyAmount);
                PVNodeLib._subVolume(sellOB, priceIdx, buyAmount);

                deposits[o.seller][tokenA] -= buyAmount;
                deposits[msg.sender][tokenB] -= amountGiven;
                IERC20(tokenA).transfer(msg.sender, buyAmount);
                IERC20(tokenB).transfer(o.seller, amountGiven);
                
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
        revert("Price already exist in orderbook");
    }

    function getIndexOfPrice(uint64 price) external view returns (uint256) {
        for (uint256 i = 0; i < sellOB.length; i++) {
            if (sellOB[i].price == price) {
                return i;
            }
        }
        revert("Price is not in the array");
    }
    // sellOB + buyOB functions end here

    function collectFees() external onlyOwner returns (bool) {
        IERC20(tokenA).transfer(msg.sender, tokenAaccumulatedFee);
        IERC20(tokenB).transfer(msg.sender, tokenBaccumulatedFee);
        tokenAaccumulatedFee = 0;
        tokenBaccumulatedFee = 0;
        return true;
    }
}


contract OBXFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "Token addresses are identical");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Token address cannot be null");
        require(getPair[token0][token1] == address(0), "Pair already exist");

        address _feeReceiver = 0x46656Be8b381aDAe1fF535fF9872B6485813BD7f;

        pair = address(new OBXExchange(tokenA, tokenB, _feeReceiver));

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        return pair;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}



